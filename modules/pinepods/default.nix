{
  config,
  lib,
  ...
}: let
  name = "pinepods";
  dbName = "${name}-db";
  valkeyName = "${name}-valkey";

  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Media & Downloads";
  displayName = "Pinepods";
  description = "Podcast Server";
in {
  imports = import ../mkAliases.nix config lib name [name dbName valkeyName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminProvisioning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to provision an admin account automatically.
          If disabled, you will be prompted to create an admin account manually on boot.

          See <https://www.pinepods.online/docs/tutorial-basics/environment-variables#initial-admin-account-setup>
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username for the admin user";
      };
      fullname = lib.mkOption {
        type = lib.types.str;
        default = "Admin";
        description = "Full name for the admin user";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email address for the admin user ";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin user password";
      };
    };
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "pinepods";
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

          - <https://www.pinepods.online/docs/tutorial-basics/environment-variables#oidc-openid-connect-configuration>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
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
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
      ${cfg.oidc.adminGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
        require_pkce = false;
        pkce_challenge_method = "";
        token_endpoint_auth_method = "client_secret_post";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/callback"
          "pinepods://auth/callback" # mobile app
        ];
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "docker.io/madeofpendletonwool/pinepods:0.9.0";
        user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
        volumeMap = {
          downloads = "${storage}/downloads:/opt/pinepods/downloads";
          backups = "${storage}/backups:/opt/pinepods/backups";
        };

        extraEnv =
          {
            PUID = config.nps.defaultUid;
            PGID = config.nps.defaultGid;
            SEARCH_API_URL = "https://search.pinepods.online/api/search";
            PEOPLE_API_URL = "https://people.pinepods.online";
            HOSTNAME = cfg.containers.${name}.traefik.serviceUrl;
          }
          // (let
            db = cfg.containers.${dbName}.extraEnv;
          in {
            DB_TYPE = "postgresql";
            DB_HOST = dbName;
            DB_PORT = 5432;
            DB_USER = db.POSTGRES_USER;
            DB_PASSWORD = db.POSTGRES_PASSWORD;
            DB_NAME = db.POSTGRES_DB;

            VALKEY_HOST = valkeyName;
            VALKEY_PORT = 6379;
          })
          // lib.optionalAttrs cfg.adminProvisioning.enable {
            USERNAME = cfg.adminProvisioning.username;
            FULLNAME = cfg.adminProvisioning.fullname;
            EMAIL = cfg.adminProvisioning.email;
            PASSWORD.fromFile = cfg.adminProvisioning.passwordFile;
          }
          // lib.optionalAttrs cfg.oidc.enable (let
            autheliaUrl = config.nps.containers.authelia.traefik.serviceUrl;
          in {
            OIDC_PROVIDER_NAME = "Authelia";
            OIDC_CLIENT_ID = name;
            OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            OIDC_AUTHORIZATION_URL = "${autheliaUrl}/api/oidc/authorization";
            OIDC_TOKEN_URL = "${autheliaUrl}/api/oidc/token";
            OIDC_USER_INFO_URL = "${autheliaUrl}/api/oidc/userinfo";
            OIDC_SCOPE = "openid profile email groups";
            OIDC_ROLES_CLAIM = "groups";
            OIDC_USER_ROLE = cfg.oidc.userGroup;
            OIDC_ADMIN_ROLE = cfg.oidc.adminGroup;
            OIDC_DISABLE_STANDARD_LOGIN = lib.mkDefault true;
            OIDC_BUTTON_TEXT = "Authelia";
            OIDC_BUTTON_COLOR = "#000000";
            OIDC_BUTTON_TEXT_COLOR = "#FFFFFF";
          });

        wantsContainer = [dbName valkeyName];

        stack = name;
        port = 8040;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "pinepods";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:pinepods";
        };
      };

      ${dbName} = {
        image = "docker.io/postgres:18";
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";

        extraEnv = {
          POSTGRES_DB = "pinepods";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -d pinepods -U ${cfg.db.username}";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
        };

        stack = name;
        glance = {
          inherit category;
          name = "Postgres";
          parent = name;
          icon = "di:postgres";
        };
      };

      ${valkeyName} = {
        image = "docker.io/valkey/valkey:9-alpine";
        stack = name;
        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "valkey-cli ping";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
        };

        glance = {
          parent = name;
          name = "Valkey";
          icon = "di:valkey";
          inherit category;
        };
      };
    };
  };
}
