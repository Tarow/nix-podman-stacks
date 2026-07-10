{
  config,
  lib,
  ...
}: let
  stackName = "sparky-fitness";
  frontendName = "${stackName}-frontend";
  backendName = "${stackName}-backend";
  dbName = "${stackName}-db";

  storage = "${config.nps.storageBaseDir}/${stackName}";
  cfg = config.nps.stacks.${stackName};

  category = "General";
  displayName = "Sparky Fitness";
  description = "Fitness Tracking Platform";
in {
  imports = import ../mkAliases.nix config lib stackName [frontendName backendName dbName];

  options.nps.stacks.${stackName} = {
    enable = lib.mkEnableOption stackName;
    betterAuthSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the BetterAuth secret key.
        Can be generated using `openssl rand -hex 32`

        See <https://codewithcj.github.io/SparkyFitness/install/environment-variables#essential-configuration>
      '';
    };
    apiEncryptionKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the api encryption key.
        Can be generated using `openssl rand -hex 32`

        See <https://codewithcj.github.io/SparkyFitness/install/environment-variables#essential-configuration>
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://codewithcj.github.io/SparkyFitness/install/environment-variables/#optional-configuration>
      '';
      example = {
        SOME_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        SOME_VALUE = "some_value";
      };
    };
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "sparkyfitness";
        description = "Database user name";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the database password";
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

          - <https://codewithcj.github.io/SparkyFitness/install/environment-variables#optional-configuration>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${stackName}_admin";
        description = "Users of this group will be assigned admin rights";
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${stackName}_user";
        description = "Users of this group will be able to log in";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
      ${cfg.oidc.adminGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${stackName} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = stackName;
        claims_policy = stackName;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${frontendName}.traefik.serviceUrl}/api/auth/sso/callback/authelia"
        ];
        token_endpoint_auth_method = "client_secret_basic";
      };

      # SparkyFitness doesn't seem to read claims from the userinfo endpoint
      settings.identity_providers.oidc.claims_policies.${stackName}.id_token = [
        "email"
        "email_verified"
        "preferred_username"
        "name"
        "groups"
      ];

      settings.identity_providers.oidc.authorization_policies.${stackName} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = [
              "group:${cfg.oidc.adminGroup}"
              "group:${cfg.oidc.userGroup}"
            ];
          }
        ];
      };
    };

    services.podman.containers = {
      ${frontendName} = {
        image = "ghcr.io/codewithcj/sparkyfitness-frontend:v0.17.3";

        extraEnv = {
          SPARKY_FITNESS_FRONTEND_URL = cfg.containers.${frontendName}.traefik.serviceUrl;
          SPARKY_FITNESS_SERVER_HOST = backendName;
          SPARKY_FITNESS_SERVER_PORT = 3010;
        };

        wantsContainer = [backendName];

        stack = stackName;
        port = 80;
        traefik.name = stackName;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "sparky-fitness";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = stackName;
          icon = "di:sparky-fitness";
        };
      };

      ${backendName} = {
        image = "ghcr.io/codewithcj/sparkyfitness-server:v0.17.3";

        volumeMap = {
          backup = "${storage}/backup:/app/SparkyFitnessServer/backup";
          uploads = "${storage}/uploads:/app/SparkyFitnessServer/uploads";
        };

        extraEnv =
          {
            SPARKY_FITNESS_DB_USER = cfg.db.username;
            SPARKY_FITNESS_DB_HOST = dbName;
            SPARKY_FITNESS_DB_NAME = "sparkyfitness";
            SPARKY_FITNESS_DB_PASSWORD.fromFile = cfg.db.passwordFile;
            SPARKY_FITNESS_APP_DB_USER = "sparkyfitness";
            SPARKY_FITNESS_APP_DB_PASSWORD.fromFile = cfg.db.passwordFile;

            BETTER_AUTH_SECRET.fromFile = cfg.betterAuthSecretFile;
            SPARKY_FITNESS_API_ENCRYPTION_KEY.fromFile = cfg.apiEncryptionKeyFile;

            SPARKY_FITNESS_FRONTEND_URL = cfg.containers.${frontendName}.traefik.serviceUrl;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            SPARKY_FITNESS_DISABLE_EMAIL_LOGIN = lib.mkDefault true;
            SPARKY_FITNESS_OIDC_AUTH_ENABLED = true;
            SPARKY_FITNESS_OIDC_ISSUER_URL = config.nps.containers.authelia.traefik.serviceUrl;
            SPARKY_FITNESS_OIDC_CLIENT_ID = stackName;
            SPARKY_FITNESS_OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            SPARKY_FITNESS_OIDC_PROVIDER_SLUG = "authelia";
            SPARKY_FITNESS_OIDC_PROVIDER_NAME = "Authelia";
            SPARKY_FITNESS_OIDC_AUTO_REGISTER = true;
            SPARKY_FITNESS_OIDC_SCOPE = "openid groups email profile";
            SPARKY_FITNESS_OIDC_ADMIN_GROUP = cfg.oidc.adminGroup;
            SPARKY_FITNESS_OIDC_TOKEN_AUTH_METHOD = "client_secret_basic";
          }
          // cfg.extraEnv;

        wantsContainer = [dbName] ++ lib.optional cfg.oidc.enable "authelia";

        stack = stackName;

        # Join Traefik network for access to Authelia
        port = 3010;
        traefik.name = backendName;

        glance = {
          inherit category;
          name = "Backend";
          parent = stackName;
          icon = "di:sparky-fitness";
        };
      };

      ${dbName} = {
        image = "docker.io/postgres:18";
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";

        extraEnv = {
          POSTGRES_DB = "sparkyfitness";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -d sparkyfitness -U ${cfg.db.username}";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
          HealthOnFailure = "kill";
        };

        stack = stackName;
        glance = {
          inherit category;
          name = "Postgres";
          parent = stackName;
          icon = "di:postgres";
        };
      };
    };
  };
}
