{
  config,
  lib,
  ...
}: let
  name = "papra";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Document Management Platform";
  displayName = "Papra";
in {
  imports = import ../mkAliases.nix config lib name [
    name
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    authSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the auth secret for Papra.
        You can generate a secret using `openssl rand -hex 48`.

        See <https://docs.papra.app/self-hosting/configuration/#auth_secret>
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.

        See <https://docs.papra.app/self-hosting/configuration/#configuration-variables>
      '';
      example = {
        SOME_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        FOO = "bar";
      };
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:
          - <https://www.authelia.com/integration/openid-connect/clients/papra/>
          - <https://docs.papra.app/guides/setup-custom-oauth2-providers/>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = ''
          Users of this group will be able to log in
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/oauth2/callback/authelia"
        ];
        token_endpoint_auth_method = "client_secret_post";
      };

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = "group:${cfg.oidc.userGroup}";
          }
        ];
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/papra-hq/papra:26.1.0-rootless";
        user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
        volumes = [
          "${storage}/data:/app/app-data"
          "${storage}/ingestion:/app/ingestion"
        ];

        extraEnv =
          {
            AUTH_SECRET.fromFile = cfg.authSecretFile;
            APP_BASE_URL = cfg.containers.${name}.traefik.serviceUrl;
            INGESTION_FOLDER_IS_ENABLED = true;
          }
          // lib.optionalAttrs (cfg.oidc.enable) {
            AUTH_PROVIDERS_EMAIL_IS_ENABLED = lib.mkDefault false;
            AUTH_IS_REGISTRATION_ENABLED = lib.mkDefault false;
            AUTH_PROVIDERS_CUSTOMS.fromTemplate = let
              autheliaUrl = config.nps.containers.authelia.traefik.serviceUrl;
            in
              [
                {
                  providerId = "authelia";
                  providerName = "Authelia";
                  providerIconUrl = "https://www.authelia.com/images/branding/logo-cropped.png";
                  clientId = name;
                  clientSecret = "{{ file.Read `${cfg.oidc.clientSecretFile}`}}";
                  type = "oidc";
                  pkce = true;
                  discoveryUrl = "${autheliaUrl}/.well-known/openid-configuration";
                  scopes = ["openid" "profile" "email"];
                }
              ]
              |> builtins.toJSON
              |> lib.replaceStrings ["\n"] [""];
          }
          // cfg.extraEnv;

        stack = name;
        port = 1221;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "papra";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:papra";
        };
      };
    };
  };
}
