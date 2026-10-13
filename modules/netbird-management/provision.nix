{
  pkgs,
  lib,
  stackName,
  idpName,
  autheliaIssuer,
  clientId,
  adminProvisioning,
  provisionOidc,
  clientSecretFile,
  ...
}:
pkgs.writeShellApplication {
  name = "netbird-provision";
  runtimeInputs = with pkgs; [coreutils jq podman];
  text = ''
    set -o pipefail
    umask 077

    base_url=http://netbird-management-server:80
    runtime_dir=$(mktemp -d)
    container_id=""
    trap '[ -z "$container_id" ] || podman_helper rm --force "$container_id" >/dev/null 2>&1 || true; rm -rf "$runtime_dir"' EXIT

    # Helper containers must not talk to the parent Quadlet unit's systemd
    # notification channel, otherwise they tear the NetBird container down right
    # after ExecStartPost finishes.
    podman_helper() {
      env -u NOTIFY_SOCKET -u WATCHDOG_USEC podman "$@"
    }

    # Run a request through a throwaway curl container on the stack network.
    # The token is passed via a mounted curl config file, never via argv.
    # Sets `http_status` and writes the response body to `"$runtime_dir/response"`.
    request() {
      local method="$1" path="$2" body="''${3:-}"
      local header_file="$runtime_dir/curlrc"
      local -a args=(--silent --show-error --write-out '%{http_code}' --request "$method" --config /tmp/curlrc)
      local -a podman_args=(create --network ${stackName} --user 0 --volume "$header_file:/tmp/curlrc:ro")

      : > "$header_file"
      if [ -n "''${pat:-}" ]; then
        printf 'header = "Authorization: Token %s"\n' "$pat" > "$header_file"
      fi
      if [ -n "$body" ]; then
        args+=(--header 'Content-Type: application/json' --data-binary @/tmp/request.json)
        podman_args+=(--volume "$body:/tmp/request.json:ro")
      fi

      container_id=$(podman_helper "''${podman_args[@]}" curlimages/curl:8.17.0 "''${args[@]}" --output /tmp/response "$base_url$path") || return 1
      http_status=$(podman_helper start --attach "$container_id") || return 1
      podman_helper cp "$container_id:/tmp/response" "$runtime_dir/response" || return 1
      podman_helper rm "$container_id" >/dev/null
      container_id=""
    }

    # Retry transient failures (network errors, 5xx) but never a permanent 4xx.
    request_with_retry() {
      local method="$1" path="$2" body="''${3:-}"
      for attempt in $(seq 1 5); do
        if request "$method" "$path" "$body"; then
          [[ "$http_status" =~ ^2 ]] && return 0
          [[ "$http_status" =~ ^4 ]] && return 1
        fi
        sleep $((attempt * 2))
      done
      return 1
    }

    # Wait for the embedded IdP to answer before touching the management API.
    for attempt in $(seq 1 60); do
      if request GET /oauth2/.well-known/openid-configuration && [ "$http_status" = 200 ]; then break; fi
      [[ "''${http_status:-000}" =~ ^4 ]] && { echo "NetBird readiness endpoint returned HTTP $http_status" >&2; exit 1; }
      sleep 2
    done
    [ "''${http_status:-000}" = 200 ] || { echo 'NetBird readiness timed out' >&2; exit 1; }

    request_with_retry GET /api/instance || { echo "Unexpected /api/instance response: HTTP ''${http_status:-000}" >&2; exit 1; }
    setup_required=$(jq -r 'if has("setup_required") then .setup_required else empty end' "$runtime_dir/response")
    if [ "$setup_required" != true ]; then
      echo 'NetBird instance is already set up, nothing to provision.'
      exit 0
    fi

    # A PAT cannot be recovered after this run: it is returned once by /api/setup
    # and never persisted, so anything below needs the owner to be retried by
    # hand if it fails.
    jq -n \
      --arg email ${lib.escapeShellArg adminProvisioning.email} \
      --arg name ${lib.escapeShellArg adminProvisioning.name} \
      --rawfile password ${adminProvisioning.passwordFile} \
      '{email:$email,name:$name,password:$password,create_pat:true,pat_expire_in:365}' > "$runtime_dir/request.json"
    request POST /api/setup "$runtime_dir/request.json" || { echo 'NetBird setup request failed; inspect the server state before retrying.' >&2; exit 1; }
    [ "$http_status" = 200 ] || { echo "NetBird setup failed: HTTP $http_status" >&2; exit 1; }
    pat=$(jq -er '.personal_access_token // .pat // .token' "$runtime_dir/response") || { echo 'Setup succeeded but the response contained no PAT; complete the provider setup manually.' >&2; exit 1; }

    ${lib.optionalString provisionOidc ''
      # Register Authelia as a Dex connector, matched by the stable tuple
      # name + issuer + client ID so an unrelated provider is never touched.
      jq -n \
        --arg name ${idpName} \
        --arg issuer ${lib.escapeShellArg autheliaIssuer} \
        --arg client_id ${clientId} \
        --rawfile client_secret ${clientSecretFile} \
        '{type:"oidc",name:$name,issuer:$issuer,client_id:$client_id,client_secret:$client_secret}' > "$runtime_dir/request.json"

      request_with_retry GET /api/identity-providers || { echo "Provider query failed with the new PAT: HTTP ''${http_status:-000}" >&2; exit 1; }
      provider_id=$(jq -r \
        --arg name ${idpName} \
        --arg issuer ${lib.escapeShellArg autheliaIssuer} \
        --arg client_id ${clientId} \
        '.[] | select(.name == $name and .issuer == $issuer and .client_id == $client_id) | .id' "$runtime_dir/response" | head -n1)

      if [ -n "$provider_id" ]; then
        request PUT "/api/identity-providers/$provider_id" "$runtime_dir/request.json" || { echo 'NetBird provider update failed.' >&2; exit 1; }
        [[ "$http_status" =~ ^2 ]] || { echo "NetBird provider update failed: HTTP $http_status" >&2; exit 1; }
      else
        request POST /api/identity-providers "$runtime_dir/request.json" || { echo 'NetBird provider creation failed.' >&2; exit 1; }
        [[ "$http_status" =~ ^2 ]] || { echo "NetBird provider creation failed: HTTP $http_status" >&2; exit 1; }
      fi
    ''}
  '';
}
