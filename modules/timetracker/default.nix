{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "timetracker";
  dbName = "${name}-db";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Time Tracking Application";
  displayName = "TimeTracker";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key for flask
      '';
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:
          - https://github.com/DRYTRIX/TimeTracker/blob/main/docs/OIDC_SETUP.md
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
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = "Users of this group will be assigned admin rights";
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
          # SQlite doesn't seem to work properly yet. Results in permissions errors
          # https://github.com/DRYTRIX/TimeTracker/issues/42
          #"sqlite"
          "postgres"
        ];
        default = "postgres";
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the `passwordFile` option must be set.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "timetracker";
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
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/auth/oidc/callback"
        ];
      };
      settings.identity_providers.oidc.authorization_policies.${name} = {
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
      ${name} = {
        image = "ghcr.io/drytrix/timetracker:4.2.0";
        volumes = ["${storage}:/data/"];
        user = config.nps.defaultUid;
        extraEnv =
          {
            TZ = config.nps.defaultTz;
            ROUNDING_MINUTES = -1;
            SINGLE_ACTIVE_TIMER = true;
            SECRET_KEY.fromFile = cfg.secretKeyFile;
            FLASK_ENV = "production";
            FLASK_DEBUG = true;
            SESSION_COOKIE_SECURE = true;
            REMEMBER_COOKIE_SECURE = true;
            LICENSE_SERVER_ENABLED = false;
          }
          // lib.optionalAttrs (cfg.db.type == "sqlite") {
            DATABASE_URL = "sqlite:///data/timetracker.db";
          }
          // lib.optionalAttrs (cfg.db.type == "postgres") {
            DATABASE_URL.fromTemplate = "postgresql+psycopg2://${cfg.db.username}:{{ file.Read `${cfg.db.passwordFile}` }}@${dbName}:5432/timetracker";
          }
          // lib.optionalAttrs cfg.oidc.enable (let
            utils = import ../utils.nix {inherit lib config;};
          in {
            AUTH_METHOD = lib.mkDefault "both";
            OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
            OIDC_CLIENT_ID = name;
            OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            OIDC_REDIRECT_URI = "${cfg.containers.${name}.traefik.serviceUrl}/auth/oidc/callback";
            OIDC_SCOPES = utils.escapeOnDemand ''"openid profile email groups"'';
            OIDC_USERNAME_CLAIM = "preferred_username";
            OIDC_FULL_NAME_CLAIM = "name";
            OIDC_EMAIL_CLAIM = "email";
            OIDC_GROUPS_CLAIM = "groups";
            OIDC_ADMIN_GROUP = cfg.oidc.adminGroup;
          });

        extraConfig.Service.ExecStartPre = lib.optional (cfg.db.type == "sqlite") "${pkgs.coreutils}/bin/touch ${storage}/timetracker.db";
        dependsOnContainer = lib.optional (cfg.db.type == "postgres") dbName;
        port = 8080;
        stack = name;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "mdi-book-clock-outline";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "mdi:book-clock-outline";
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:17";
        volumes = ["${storage}/db:/var/lib/postgresql/data"];
        extraEnv = {
          POSTGRES_DB = "timetracker";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -d timetracker -U ${cfg.db.username}";
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
