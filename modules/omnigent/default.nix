{
  config,
  lib,
  ...
}: let
  name = "omnigent";
  dbName = "${name}-db";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "AI Coding Agent Server";
  displayName = "Omnigent";
in {
  imports = import ../mkAliases.nix config lib name [name dbName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          Omnigent has native OIDC support and handles the login flow itself.

          For details, see:
          - <https://omnigent.ai/docs/collaborate/auth#single-sign-on-oidc>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      cookieSecretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          File containing the OIDC session cookie secret (64 hex characters).
          Generate with `openssl rand -hex 32`.
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };

    db = {
      type = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
        default = "sqlite";
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the `passwordFile` option must be set.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = ''
          The PostgreSQL user to use for the database.
          Only used if db.type is set to "postgres".
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the PostgreSQL password for the database.
          Only used if db.type is set to "postgres".
        '';
      };
    };

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://omnigent.ai/docs/deploy/overview#docker-compose> for available variables.
      '';
      example = {
        OMNIGENT_SHARING_MODE = "read_only";
        OMNIGENT_FEATURES = "usage_page";
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
        token_endpoint_auth_method = "client_secret_post";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/auth/callback"
        ];
        claims_policy = name;
      };

      # No role mapping based on OIDC claims / groups. Restrict user access on Authelia level
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
        image = "ghcr.io/omnigent-ai/omnigent-server:v0.17.0";
        volumeMap.data = "${storage}/data:/data";

        environment = {
          HOST = "0.0.0.0";
          PORT = 8000;
          OMNIGENT_AUTH_ENABLED = 1;
          OMNIGENT_ACCOUNTS_AUTO_OPEN = 0;
          OMNIGENT_ACCOUNTS_BASE_URL = cfg.containers.${name}.traefik.serviceUrl;
          OMNIGENT_ADMIN_CREDENTIALS_PATH = "/data/admin-credentials";
        };
        extraEnv =
          lib.optionalAttrs (cfg.db.type == "postgres") {
            DATABASE_URL.fromTemplate = "postgresql+psycopg://${cfg.db.username}:{{ file.Read \`${cfg.db.passwordFile}\` }}@${dbName}:5432/${name}?sslmode=disable";
          }
          // lib.optionalAttrs (cfg.db.type == "sqlite") {
            DATABASE_URL = "sqlite:////data/artifacts/chat.db";
          }
          // lib.optionalAttrs cfg.oidc.enable {
            OMNIGENT_OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
            OMNIGENT_OIDC_CLIENT_ID = name;
            OMNIGENT_OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            OMNIGENT_OIDC_COOKIE_SECRET.fromFile = cfg.oidc.cookieSecretFile;
            OMNIGENT_OIDC_REDIRECT_URI = "${cfg.containers.${name}.traefik.serviceUrl}/auth/callback";
          }
          // cfg.extraEnv;

        dependsOnContainer = lib.optional (cfg.db.type == "postgres") dbName;
        wantsContainer = lib.optional cfg.oidc.enable "authelia";
        stack = name;
        port = 8000;
        traefik.name = name;
        dashboard = {
          inherit category description;
          name = displayName;
          icon = "https://raw.githubusercontent.com/omnigent-ai/omnigent/main/docs/images/omnigent-logo.svg";
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:18";
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql/data";
        extraEnv = {
          POSTGRES_DB = name;
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        stack = name;
        dashboard = {
          inherit category;
          parent = name;
          name = "Postgres";
          icon = "di:postgres"";
        };
      };
    };
  };
}
