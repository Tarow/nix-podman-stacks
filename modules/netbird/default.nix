{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "netbird";
  dashboardName = "${stackName}-dashboard";
  serverName = "${stackName}-server";

  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";

  category = "Network & Administration";
  description = "Open Source Zero Trust Networking";
  displayName = "NetBird";

  yaml = pkgs.formats.yaml {};
  netbirdUrl = cfg.containers.${dashboardName}.traefik.serviceUrl;
  # Name of the Dex connector created for Authelia; shown as the login button on
  # the embedded IdP login screen.
  idpName = "Authelia";
  provisionScript = lib.getExe (pkgs.writeShellApplication {
    name = "netbird-provision";
    runtimeInputs = with pkgs; [coreutils jq podman];
    text = ''
      set -o pipefail
      umask 077
      base_url=http://netbird-server:80
      state_dir=${lib.escapeShellArg "${storage}/.provisioning"}
      pat_file="$state_dir/setup-pat"
      secret_hash_file="$state_dir/oidc-client-secret.sha256"
      runtime_dir=$(mktemp -d)
      container_id=""
      trap '[ -z "$container_id" ] || podman_helper rm --force "$container_id" >/dev/null 2>&1 || true; rm -rf "$runtime_dir"' EXIT
      mkdir -p "$state_dir"
      chmod 700 "$state_dir"

      podman_helper() {
        env -u NOTIFY_SOCKET -u WATCHDOG_USEC podman "$@"
      }

      request() {
        local method="$1" path="$2" body="''${3:-}" header_file="$runtime_dir/curlrc"
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

      pat=""
      for attempt in $(seq 1 60); do
        if request GET /oauth2/.well-known/openid-configuration && [ "$http_status" = 200 ]; then break; fi
        [[ "''${http_status:-000}" =~ ^4 ]] && { echo "NetBird readiness endpoint returned HTTP $http_status" >&2; exit 1; }
        sleep 2
      done
      [ "''${http_status:-000}" = 200 ] || { echo 'NetBird readiness timed out' >&2; exit 1; }

      request_with_retry GET /api/instance || { echo "Unexpected /api/instance response: HTTP ''${http_status:-000}" >&2; exit 1; }
      setup_required=$(jq -r 'if has("setup_required") then .setup_required elif has("setupRequired") then .setupRequired else empty end' "$runtime_dir/response")
      [[ "$setup_required" == true || "$setup_required" == false ]] || { echo 'Missing setup_required in /api/instance response' >&2; exit 1; }

      if [ "$setup_required" = true ]; then
        jq -n \
          --arg email ${lib.escapeShellArg cfg.adminProvisioning.email} \
          --arg name ${lib.escapeShellArg cfg.adminProvisioning.name} \
          --rawfile password ${cfg.adminProvisioning.passwordFile} \
          '{email:$email,name:$name,password:$password,create_pat:true,pat_expire_in:365}' > "$runtime_dir/request.json"
        request POST /api/setup "$runtime_dir/request.json" || { echo 'NetBird setup request failed; inspect server state before retrying' >&2; exit 1; }
        [ "$http_status" = 200 ] || { echo "NetBird setup failed: HTTP $http_status" >&2; exit 1; }
        pat=$(jq -er '.personal_access_token // .pat // .token' "$runtime_dir/response") || { echo 'Setup succeeded but response contained no PAT; recover the owner credential manually' >&2; exit 1; }
        printf '%s' "$pat" > "$pat_file.tmp"
        chmod 600 "$pat_file.tmp"
        mv -f "$pat_file.tmp" "$pat_file"
      elif [ ! -s "$pat_file" ]; then
        echo 'NetBird setup is complete but no persisted setup PAT exists. Restore or replace the PAT; setup will not be repeated.' >&2
        exit 1
      else
        pat=$(< "$pat_file")
      fi

      request_with_retry GET /api/identity-providers || { echo "NetBird PAT rejected or provider query failed: HTTP ''${http_status:-000}" >&2; exit 1; }
      cp "$runtime_dir/response" "$runtime_dir/providers.json"
      secret_hash=$(sha256sum ${cfg.oidc.clientSecretFile} | cut -d' ' -f1)
      jq -n \
        --arg name ${lib.escapeShellArg idpName} \
        --arg issuer ${lib.escapeShellArg config.nps.containers.authelia.traefik.serviceUrl} \
        --arg client_id netbird \
        --rawfile client_secret ${cfg.oidc.clientSecretFile} \
        '{type:"oidc",name:$name,issuer:$issuer,client_id:$client_id,client_secret:$client_secret}' > "$runtime_dir/request.json"
      provider_id=$(jq -r --arg name ${lib.escapeShellArg idpName} --arg issuer ${lib.escapeShellArg config.nps.containers.authelia.traefik.serviceUrl} --arg client_id netbird '.[] | select(.name == $name and .issuer == $issuer and .client_id == $client_id) | .id' "$runtime_dir/providers.json" | head -n1)
      if [ -n "$provider_id" ]; then
        stored_secret_hash=$(cat "$secret_hash_file" 2>/dev/null || true)
        if [ "$stored_secret_hash" != "$secret_hash" ]; then
          request_with_retry PUT "/api/identity-providers/$provider_id" "$runtime_dir/request.json" || { echo "NetBird provider update failed: HTTP ''${http_status:-000}" >&2; exit 1; }
        fi
      else
        request POST /api/identity-providers "$runtime_dir/request.json" || { echo 'NetBird provider creation failed' >&2; exit 1; }
        [[ "$http_status" =~ ^2 ]] || { echo "NetBird provider creation failed: HTTP $http_status" >&2; exit 1; }
      fi
      printf '%s\n' "$secret_hash" > "$secret_hash_file.tmp"
      chmod 600 "$secret_hash_file.tmp"
      mv -f "$secret_hash_file.tmp" "$secret_hash_file"
    '';
  });
in {
  imports = import ../mkAliases.nix config lib stackName [dashboardName serverName];

  options.nps.stacks.${stackName} = {
    enable = lib.mkEnableOption stackName;
    authSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the shared secret for relay authentication.
        Can be generated using `openssl rand -hex 32`.

        For details see <https://docs.netbird.io/selfhosted/configuration-files#server-settings>
      '';
    };
    storeEncryptionKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the 32-byte encryption key for sensitive data at rest.
        Can be generated using `openssl rand -base64 32`.

        For details see <https://docs.netbird.io/selfhosted/configuration-files#store-settings>
      '';
    };
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Netbird settings. Will be provided in the `configuration.yml`.
        The config will be templated using `gomplate`, so you can refer to secrets etc.

        For details see <https://docs.netbird.io/selfhosted/configuration-files#config-yaml>
      '';
    };
    adminProvisioning = {
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email for the initial NetBird owner account.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "NetBird Admin";
        description = "Display name for the initial NetBird owner account.";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "File containing the initial NetBird owner password.";
      };
    };
    oidc = {
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${stackName}_user";
        description = "Users of this group will be able to log in";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = {
      oidc.clients.${stackName} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = stackName;
        require_pkce = false;
        pkce_challenge_method = "";
        consent_mode = "implicit";
        audience = [stackName];
        scopes = ["openid" "profile" "email"];
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = ["${netbirdUrl}/oauth2/callback"];
        token_endpoint_auth_method = "client_secret_post";
        # NetBird's embedded Dex OIDC connector hard-requires a `name` claim, which
        # Authelia does not emit in the ID token by default.
        # See <https://github.com/netbirdio/netbird/issues/5143>
        claims_policy = stackName;
      };

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
      # See <https://github.com/TwiN/gatus/issues/638>
      settings.identity_providers.oidc.authorization_policies.${stackName} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = "group:${cfg.oidc.userGroup}";
          }
        ];
      };

      settings.identity_providers.oidc.claims_policies.${stackName}.id_token = [
        "email"
        "email_verified"
        "preferred_username"
        "name"
        "groups"
      ];

      settings.identity_providers.oidc.cors = {
        allowed_origins_from_client_redirect_uris = true;
        endpoints = [
          "authorization"
          "token"
          "revocation"
          "introspection"
          "userinfo"
        ];
      };
    };

    nps.stacks.${stackName}.settings = {
      server = {
        listenAddress = ":80";
        exposedAddress = "${netbirdUrl}:443";
        stunPorts = [
          3478
        ];
        metricsPort = 9090;
        healthcheckAddress = ":9000";
        logLevel = "info";
        logFile = "console";

        authSecret = "{{ file.Read `${cfg.authSecretFile}`}}";
        dataDir = "/var/lib/netbird";

        auth = {
          issuer = "${netbirdUrl}/oauth2";
          signKeyRefreshEnabled = true;
          dashboardRedirectURIs = [
            "${netbirdUrl}/nb-auth"
            "${netbirdUrl}/nb-silent-auth"
          ];
          cliRedirectURIs = [
            "http://localhost:53000/"
          ];
        };

        reverseProxy = {
          trustedHTTPProxies = [
            config.nps.stacks.traefik.network.subnet
          ];
        };

        store = {
          engine = "sqlite";
          encryptionKey = "{{ file.Read `${cfg.storeEncryptionKeyFile}`}}";
        };
      };
    };

    services.podman.containers = {
      ${dashboardName} = {
        image = "docker.io/netbirdio/dashboard:v2.33.0";

        extraEnv = {
          NETBIRD_MGMT_API_ENDPOINT = cfg.containers.${serverName}.traefik.serviceUrl;
          NETBIRD_MGMT_GRPC_API_ENDPOINT = cfg.containers.${serverName}.traefik.serviceUrl;

          AUTH_AUDIENCE = "netbird-dashboard";
          AUTH_CLIENT_ID = "netbird-dashboard";
          AUTH_AUTHORITY = "${netbirdUrl}/oauth2";
          USE_AUTH0 = false;
          AUTH_SUPPORTED_SCOPES.fromFile = pkgs.writeText "scopes" "openid profile email groups";
          AUTH_REDIRECT_URI = "/nb-auth";
          AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
        };

        stack = stackName;
        port = 80;
        labels."traefik.http.routers.${dashboardName}.priority" = "1";
        traefik = {
          name = dashboardName;
          subDomain = stackName;
        };
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "netbird";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = stackName;
          icon = "di:netbird";
        };
      };

      ${serverName} = {
        image = "ghcr.io/netbirdio/netbird-server:0.78.0";
        environment.NB_SETUP_PAT_ENABLED = true;
        ports = ["3478:3478/udp"];
        volumeMap.data = "${storage}/data:/var/lib/netbird";

        templateMount = [
          {
            templatePath = "${yaml.generate "netbird_config" cfg.settings}";
            destPath = "/etc/netbird/config.yaml";
          }
        ];

        exec = "--config /etc/netbird/config.yaml";
        extraConfig.Service.ExecStartPost = [provisionScript];
        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "bash -c '</dev/tcp/127.0.0.1/80'";
          HealthInterval = "5s";
          HealthTimeout = "3s";
          HealthRetries = 12;
          HealthStartPeriod = "5s";
          HealthOnFailure = "kill";
        };

        stack = stackName;
        port = 80;

        # The combined server shares its host with the dashboard, so restrict its
        # router to the server paths (HTTP and gRPC, which is multiplexed on the
        # same port and speaks h2c).
        traefik = {
          name = serverName;
          subDomain = stackName;
          scheme = "h2c";
          rule = "Host(`${cfg.containers.${serverName}.traefik.serviceHost}`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`) || PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`))";
        };
        glance = {
          inherit category;
          name = "Server";
          parent = stackName;
          icon = "di:netbird";
        };
      };
    };
  };
}
