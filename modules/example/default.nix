{
  config,
  lib,
  ...
}: let
  # The name of your stack/service
  name = "example";

  # Reference to the stack config (this)
  cfg = config.nps.stacks.${name};

  # Optional database & cache, if you don't need them, delete these lines
  dbName = "${name}-db";
  redisName = "${name}-redis";

  # Reference to storage used for volumes.
  # Delete if no volumes are required.
  # Prefer to use "storage" for volumes and "mediaStorage" only large media files such as videos etc.
  storage = "${config.nps.storageBaseDir}/${name}";
  mediaStorage = "${config.nps.mediaStorageBaseDir}";

  # Metadata for Homepage and Glance
  category = "General";
  description = "Example Stack Description";
  displayName = "Example Stack";
in {
  imports = import ../mkAliases.nix config lib name [
    # Provides aliases from nps.stacks.${name}.containers.<containername> & nps.containers.<containername> to services.podman.containers.<containername>)
    # Remove non existing containers from this list
    name
    dbName
    redisName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    # Each service handles users differently, so you will need to determine the appropriate configuration.
    # If the service allows for automatic admin provisioning (e.g. via env variables), include this block.
    adminProvisioning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to automatically create an admin user.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username for the admin user";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin user password";
      };
    };

    # If the service doesn't provide OIDC delete this block
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia.
        '';
      };

      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;

      # Some services don't support role mapping (user/admin) based on groups.
      # In that case, only include the userGroup
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

    # Include block if service needs a separate database
    db = {
      # "type" option is only needed for services supporting multiple databases
      type = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
        default = "sqlite";
        description = ''
          Type of the database to use.
          If set to "postgres", the passwordFile option must be set.
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "The file containing the database password.";
      };
    };

    # Extra environment variables that will be passed through to the service.
    # Useful for services that allow lots of configurations via environment variables
    # If not applicable, remove block
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).
      '';
    };

    # You can add more options if they seem useful for the provided service
  };

  config = lib.mkIf cfg.enable {
    # Creates the groups in LLDAP
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
      ${cfg.oidc.adminGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      # Check service documentation for correct values for these settings (e.g. PKCE, redirect URIS, ...)
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        redirect_uris = [
          # Make sure this is the correct URI for your service
          "${cfg.containers.${name}.traefik.serviceUrl}/oidc/callback"
        ];
      };

      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = [
              # Include only existing groups here
              "group:${cfg.oidc.userGroup}"
              "group:${cfg.oidc.adminGroup}"
            ];
          }
        ];
      };
    };

    services.podman.containers = {
      ${name} = {
        # Replace with the correct image
        # Use stable tag (not "latest"), Renovate will update images automatically
        image = "docker.io/example/image:v1.2.3";

        # Declare dependencies to other containers. Remove if not applicable
        wantsContainer =
          lib.optional (cfg.db.type == "postgres") dbName
          ++ [redisName]
          ++ lib.optional cfg.oidc.enable "authelia";

        # Needed for multi-container stacks. Will create a shared network for all containers sharing the same stack
        stack = name;

        volumeMap = {
          # Adjust volumes to what the service needs
          data = "${storage}/data:/app/data";
          config = "${storage}/config:/app/config";
          media = "${mediaStorage}:/media";
        };

        # Environment configuration
        extraEnv =
          {
            APP_PORT = "8080";
            DB_TYPE = cfg.db.type;
            DB_HOST = lib.mkIf (cfg.db.type == "postgres") dbName;
            REDIS_HOST = redisName;
            DB_PASS.fromFile = lib.mkIf (cfg.db.type == "postgres" "sqlite") cfg.db.passwordFile;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            # OIDC config will differ slightly for every service. Adjust variables as needed
            OIDC_AUTH_ENABLED = true;
            OIDC_PROVIDER_NAME = "Authelia";
            OIDC_SIGNUP_ENABLED = true;
            OIDC_CONFIGURATION_URL = "${config.nps.containers.authelia.traefik.serviceUrl}/.well-known/openid-configuration";
            OIDC_CLIENT_ID = name;
            OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            OIDC_ADMIN_GROUP = cfg.oidc.adminGroup;
            OIDC_USER_GROUP = cfg.oidc.userGroup;
          }
          // cfg.extraEnv;

        # This is the internal (in container) port that Traefik will forward traffic to
        port = 8080;

        # Name that will be used to register service within Traefik
        traefik.name = name;

        # Dashboard configurations
        dashboard = {
          inherit category description;
          name = displayName;
          icon = "di:react";
        };
      };

      # Delete if stack doesn't require a database
      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:18";
        stack = name;
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";
        extraEnv = {
          POSTGRES_DB = "example";
          POSTGRES_USER = "example";
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        dashboard = {
          inherit category;
          name = "Postgres";
          icon = "di:postgres";
          parent = name;
        };
        homepage.category = null;
      };

      # Delete if stack doesn't require redis
      ${redisName} = {
        image = "docker.io/redis:8";
        stack = name;
        dashboard = {
          inherit category;
          name = "Redis";
          icon = "di:redis";
          parent = name;
        };
        homepage.category = null;
      };
    };
  };
}
