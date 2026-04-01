{
  config,
  lib,
  ...
}: let
  name = "dawarich";

  dbName = "${name}-db";
  redisName = "${name}-redis";
  sidekiqName = "${name}-sidekiq";

  storage = "${config.nps.storageBaseDir}/${name}";

  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Location History Tracker";
  displayName = "Dawarich";

  env =
    {
      RAILS_ENV = "production";
      REDIS_URL = "redis://${redisName}:6379";
      DATABASE_HOST = dbName;
      DATABASE_PORT = 5432;
      DATABASE_USERNAME = cfg.db.username;
      DATABASE_PASSWORD.fromFile = cfg.db.passwordFile;
      DATABASE_NAME = "dawarich";
      APPLICATION_HOSTS = cfg.containers.${name}.traefik.serviceHost;
      SELF_HOSTED = true;
      STORE_GEODATA = true;
      SECRET_KEY_BASE.fromFile = cfg.secretKeyFile;
    }
    // lib.optionalAttrs cfg.oidc.enable {
      OIDC_CLIENT_ID = name;
      OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
      OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
      OIDC_REDIRECT_URI = "${cfg.containers.${name}.traefik.serviceUrl}/users/auth/openid_connect/callback";
      OIDC_PROVIDER_NAME = "Authelia";
      OIDC_AUTO_REGISTER = lib.mkDefault true;
      ALLOW_EMAIL_PASSWORD_REGISTRATION = lib.mkDefault false;
    };
in {
  imports = import ../mkAliases.nix config lib name [
    name
    redisName
    dbName
    sidekiqName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key base.
        Can be generated using `openssl rand -hex 16`
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://dawarich.app/docs/self-hosting/environment-variables>
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
          and setup the necessary configuration in Immich.

          For details, see:

          - <https://dawarich.app/docs/self-hosting/configuration/oidc-authentication/>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;

      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "dawarich";
        description = ''
          The PostgreSQL user to use for the database.
        '';
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
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          env.OIDC_REDIRECT_URI
        ];
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
        image = "docker.io/freikin/dawarich:1.6.0";
        volumeMap = {
          public = "${storage}/public:/var/app/public";
          watched = "${storage}/watched:/var/app/tmp/imports/watched";
          storage = "${storage}/storage:/var/app/storage";
          dbData = "${storage}/db_data:/dawarich_db_data";
        };
        extraEnv = env // cfg.extraEnv;

        extraPodmanArgs = ["-ti"];
        entrypoint = " web-entrypoint.sh";
        exec = "bin/rails server -p 3000 -b ::";

        wantsContainer = [dbName redisName];

        port = 3000;

        stack = name;
        traefik.name = name;

        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "dawarich";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:dawarich";
        };
      };

      ${sidekiqName} = {
        image = "docker.io/freikin/dawarich:1.6.0";
        volumeMap = {
          public = "${storage}/public:/var/app/public";
          watched = "${storage}/watched:/var/app/tmp/imports/watched";
          storage = "${storage}/storage:/var/app/storage";
        };
        extraEnv = env // cfg.extraEnv;

        wantsContainer = [name dbName redisName];

        extraPodmanArgs = ["-ti"];
        entrypoint = "sidekiq-entrypoint.sh";
        exec = "sidekiq";

        stack = name;
        glance = {
          inherit category;
          name = "Dawarich Sidekiq";
          parent = name;
          icon = "di:immich";
        };
      };

      ${redisName} = {
        image = "docker.io/redis:8";
        stack = name;
        volumeMap.shared = "${storage}/shared:/data";
        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "redis-cli --raw incr ping";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
          HealthOnFailure = "kill";
        };
        glance = {
          inherit category;
          parent = name;
          name = "Redis";
          icon = "di:redis";
        };
      };

      ${dbName} = {
        image = "docker.io/postgis/postgis:18-3.6-alpine";
        volumeMap = {
          data = "${storage}/postgres:/var/lib/postgresql";
          shared = "${storage}/shared:/data";
        };

        extraEnv = {
          POSTGRES_DB = "dawarich";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -d dawarich -U ${cfg.db.username}";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
          HealthOnFailure = "kill";
        };

        stack = name;
        glance = {
          inherit category;
          name = "Postgres";
          parent = name;
          icon = "di:postgres";
        };
      };
    };
  };
}
