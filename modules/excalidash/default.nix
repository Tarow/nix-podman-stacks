{
  config,
  lib,
  ...
}: let
  name = "excalidash";
  backendName = "${name}-backend";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Self-hosted Excalidraw workspace with saved drawings, collections, real-time collaboration, and version history.";
  displayName = "ExcaliDash";
in {
  imports = import ../mkAliases.nix config lib name [name backendName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the JWT secret.
        Generate with `openssl rand -hex 32`.

        See <https://excalidash.xyz/reference/environment#authentication>
      '';
    };

    csrfSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the CSRF secret.
        Generate with `openssl rand -hex 32`.

        See <https://excalidash.xyz/reference/environment#security>
      '';
    };

    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and configure ExcaliDash for OIDC-only authentication (AUTH_MODE=oidc_enforced).

          For details, see:
          - <https://www.authelia.com/integration/openid-connect/clients/>
          - <https://excalidash.xyz/guide/authentication#configure-openid-connect>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = "Users of this group will be granted admin rights via OIDC groups claim";
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users must be a part of this group to be able to log in (enforced on Authelia level)";
      };
    };

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables for the backend container.
        Supports fromFile, fromTemplate, fromCommand.

        See <https://excalidash.xyz/reference/environment#environment-reference>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.adminGroup} = {};
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/oidc/callback"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        claims_policy = name;
      };

      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = "group:${cfg.oidc.userGroup}";
          }
        ];
      };

      settings.identity_providers.oidc.claims_policies.${name}.id_token = [
        "email"
        "email_verified"
        "alt_emails"
        "preferred_username"
        "name"
        "groups"
      ];
    };

    services.podman.containers = {
      ${name} = {
        image = "docker.io/zimengxiong/excalidash-frontend:0.6.5";
        user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
        environment = {
          BACKEND_URL = "${backendName}:8000";
        };

        dependsOnContainer = [backendName];
        stack = name;
        port = 8080;
        traefik.name = name;
        dashboard = {
          inherit category description;
          name = displayName;
          icon = "sh:excalidash";
        };
      };

      ${backendName} = {
        image = "docker.io/zimengxiong/excalidash-backend:0.6.5";

        extraConfig.Container = {
          HealthCmd = "node -e \"require('http').get('http://127.0.0.1:8000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))\"";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "20s";
          HealthOnFailure = "kill";
          UserNS = "keep-id:uid=1001,gid=1001";
        };

        volumeMap.data = "${storage}/data:/app/prisma";

        # Join Traefik network for internal communication required for OIDC
        network = lib.optional cfg.oidc.enable config.nps.stacks.traefik.network.name;
        extraEnv =
          {
            NODE_ENV = "production";
            DATABASE_PROVIDER = "sqlite";
            DATABASE_URL = "file:/app/prisma/dev.db";
            PORT = 8000;
            TRUST_PROXY = 1;
            FRONTEND_URL = cfg.containers.${name}.traefik.serviceUrl;
            JWT_SECRET.fromFile = cfg.jwtSecretFile;
            CSRF_SECRET.fromFile = cfg.csrfSecretFile;
            AUTH_MODE =
              if cfg.oidc.enable
              then "oidc_enforced"
              else "disabled";
          }
          // lib.optionalAttrs cfg.oidc.enable {
            OIDC_ISSUER_URL = config.nps.containers.authelia.traefik.serviceUrl;
            OIDC_CLIENT_ID = name;
            OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            OIDC_REDIRECT_URI = "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/oidc/callback";
            OIDC_ADMIN_GROUPS = cfg.oidc.adminGroup;
            OIDC_SCOPES = "openid profile email groups";
            OIDC_JIT_PROVISIONING = true;
            OIDC_FIRST_USER_ADMIN = true;
            OIDC_TOKEN_ENDPOINT_AUTH_METHOD = "client_secret_basic";
          }
          // cfg.extraEnv;

        wantsContainer = lib.optional cfg.oidc.enable "authelia";
        stack = name;
        dashboard = {
          inherit category;
          name = "Backend";
          parent = name;
          icon = "sh:excalidash";
        };
      };
    };
  };
}
