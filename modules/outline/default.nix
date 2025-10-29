{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "outline";
  dbName = "${name}-db";
  redisName = "${name}-redis";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Collaborative Knowledge Base";
  displayName = "Outline";

  storage = "${config.nps.storageBaseDir}/${name}";
in {
  imports = import ../mkAliases.nix config lib name [name dbName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key.
        Can be generated using `openssl rand -hex 32`

        See <https://github.com/outline/outline/blob/main/.env.sample>
      '';
    };
    utilsSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the utils secret.
        Can be generated using `openssl rand -hex 32`

        See <https://github.com/outline/outline/blob/main/.env.sample>
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Can be used to pass secrets such as the `TMDB_ACCESS_TOKEN`.

        See <https://github.com/outline/outline/blob/main/.env.sample>
      '';
      example = {
        TMDB_ACCESS_TOKEN = {
          fromFile = "/run/secrets/tmdb_access_token";
        };
        DEFAULT_LANGUAGE = "en_US";
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

          - <https://www.authelia.com/integration/openid-connect/clients/outline/>
          - <https://docs.getoutline.com/s/hosting/doc/oidc-8CPBm6uC0I>
        '';
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          The file containing the client secret for the OIDC client that will be registered in Authelia.
        '';
      };
      clientSecretHash = lib.mkOption {
        type = lib.types.str;
        description = ''
          The hashed client_secret. Will be set in the Authelia client config.
          For examples on how to generate a client secret, see

          <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "outline";
        description = "Database user name";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the database password";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Outline";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/auth/oidc.callback"
        ];
        scopes = ["openid" "offline_access" "profile" "email"];
        grant_types = ["authorization_code" "refresh_token"];
        token_endpoint_auth_method = "client_secret_post";
      };

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
      # See <https://github.com/outline/outline/issues/8168>
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
        image = "docker.io/outlinewiki/outline:1.0.1";
        volumes = ["${storage}/data:/var/lib/outline/data"];
        extraEnv = let
          utils = import ../utils.nix {inherit lib config;};
        in
          {
            URL = cfg.containers.${name}.traefik.serviceUrl;
            PORT = 3000;
            REDIS_URL = "redis://${redisName}:6379";
            DATABASE_URL.fromTemplate = "postgres://${cfg.db.username}:{{ file.Read `${cfg.db.passwordFile}` }}@${dbName}/outline";
            PGSSLMODE = "disable";
            SECRET_KEY.fromFile = cfg.secretKeyFile;
            UTILS_SECRET.fromFile = cfg.utilsSecretFile;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            OIDC_ISSUER_URL = config.nps.containers.authelia.traefik.serviceUrl;
            OIDC_CLIENT_ID = name;
            OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            OIDC_SCOPES = utils.escapeOnDemand ''"openid offline_access profile email"'';
            OIDC_DISPLAY_NAME = "Authelia";
          }
          // cfg.extraEnv;

        stack = name;
        port = 3000;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "outline";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:outline";
        };
      };

      ${redisName} = {
        image = "docker.io/redis:8.2";
        stack = name;

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "redis-cli ping";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
        };

        glance = {
          parent = name;
          name = "Redis";
          icon = "di:redis";
          inherit category;
        };
      };

      ${dbName} = {
        image = "docker.io/postgres:17";
        volumes = ["${storage}/db:/var/lib/postgresql/data"];
        extraEnv = {
          POSTGRES_DB = "outline";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -d outline -U ${cfg.db.username}";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
        };

        stack = name;
        glance = {
          parent = name;
          name = "Postgres";
          icon = "di:postgres";
          inherit category;
        };
      };
    };
  };
}
