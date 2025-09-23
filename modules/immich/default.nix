{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "immich";

  dbName = "${name}-db";
  redisName = "${name}-redis";
  mlName = "${name}-machine-learning";

  storage = "${config.nps.storageBaseDir}/${name}";
  mediaStorage = "${config.nps.mediaStorageBaseDir}";
  cfg = config.nps.stacks.${name};

  env =
    {
      DB_HOSTNAME = dbName;
      DB_USERNAME = "postgres";
      DB_DATABASE_NAME = "immich";
      REDIS_HOSTNAME = redisName;
      NODE_ENV = "production";
      UPLOAD_LOCATION = "/usr/src/app/upload";
    }
    // lib.optionalAttrs (cfg.settings != null) {
      IMMICH_CONFIG_FILE = "/usr/src/app/config/config.json";
    };

  json = pkgs.formats.json {};
in {
  imports = import ../mkAliases.nix config lib name [
    name
    redisName
    dbName
    mlName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr json.type;
      description = ''
        Settings that will be written to the 'config.json' file.
        If you want to configure settings through the UI, set this option to null.
        In that case, no managed `config.json` will be provided.

        For details to the config file see <https://immich.app/docs/install/config-file/>
      '';
      apply = settings:
        if (settings != null)
        then (json.generate "config.json" settings)
        else null;
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration in Immich.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/immich/>
          - <https://immich.app/docs/administration/oauth/>
        '';
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing that client secret that will be used to authenticate against Authelia.
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
        description = ''
          Users of this group will be assigned admin rights in Immich.
          The role is only used on user creation and not synchronized after that.

          See <https://immich.app/docs/administration/oauth/>
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in to Immich";
      };
    };
    dbPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the PostgreSQL password for the Immich database.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap = lib.mkIf (cfg.oidc.enable) {
      groups = {
        ${cfg.oidc.adminGroup} = {};
        ${cfg.oidc.userGroup} = {};
      };
      userSchemas = {
        immich-quota.attributeType = "INTEGER";
      };
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      settings.authentication_backend = {
        ldap.attributes.extra = {
          immich-quota = {
            name = "immich_quota";
            value_type = "integer";
          };
        };
      };
      settings.identity_providers.oidc = {
        claims_policies.${name}.custom_claims = {
          immich_quota.attribute = "immich_quota";
          immich_role.attribute = "immich_role";
        };
        scopes.${name}.claims = [
          "immich_quota"
          "immich_role"
        ];

        # Immich doesn't support blocking access to users that aren't part of a group, so we have to do it on Authelia level
        authorization_policies.${name} = {
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
      settings.definitions.user_attributes."immich_role".expression = ''"${cfg.oidc.adminGroup}" in groups ? "admin" : "user" '';

      oidc.clients.${name} = {
        client_name = "Immich";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/auth/login"
          "${cfg.containers.${name}.traefik.serviceUrl}/user-settings"
          "app.immich:///oauth-callback"
        ];
        token_endpoint_auth_method = "client_secret_post";
        scopes = [
          "openid"
          "profile"
          "email"
          name
        ];
        claims_policy = name;
      };
    };

    nps.stacks.${name}.settings = lib.mkMerge [
      (import ./config.nix)
      # If Authelia is enabled, config will be templated with gomplate. Avoid rendering issues due to double curly braces
      {
        storageTemplate.template = let
          template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
        in
          if (!cfg.oidc.enable)
          then template
          else "{{`${template}`}}";
      }
      (lib.optionalAttrs cfg.oidc.enable {
        oauth = {
          enabled = true;
          autoLaunch = false;
          autoRegister = true;
          buttonText = "Login with Authelia";
          clientId = name;
          clientSecret = ''{{ file.Read `${cfg.oidc.clientSecretFile}`}}'';
          defaultStorageQuota = 0;
          issuerUrl = config.nps.stacks.authelia.containers.authelia.traefik.serviceUrl;
          mobileOverrideEnabled = false;
          mobileRedirectUri = "";
          scope = "openid profile email ${name}";
          storageLabelClaim = "preferred_username";
          storageQuotaClaim = "immich_quota";
          roleClaim = "immich_role";
          timeout = 30000;
          tokenEndpointAuthMethod = "client_secret_post";
        };
      })
    ];

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/immich-app/immich-server:v1.143.0";
        volumes =
          [
            "${mediaStorage}/pictures/immich:${env.UPLOAD_LOCATION}"
          ]
          ++ lib.optional (
            cfg.settings != null && (!cfg.oidc.enable)
          ) "${cfg.settings}:${env.IMMICH_CONFIG_FILE}";
        templateMount = lib.optional cfg.oidc.enable {
          templatePath = cfg.settings;
          destPath = env.IMMICH_CONFIG_FILE;
        };

        environment = env;
        extraEnv.DB_PASSWORD.fromFile = cfg.dbPasswordFile;
        devices = ["/dev/dri:/dev/dri"];

        dependsOnContainer = [
          redisName
          dbName
        ];
        port = 2283;

        stack = name;
        traefik.name = name;
        homepage = {
          category = "Media & Downloads";
          name = "Immich";
          settings = {
            description = "Photo & Video Management";
            icon = "immich";
            widget.type = "immich";
          };
        };
      };

      ${redisName} = {
        image = "docker.io/redis:8.0";
        stack = name;
      };

      ${dbName} = {
        image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0";
        volumes = ["${storage}/pgdata:/var/lib/postgresql/data"];

        extraEnv = {
          POSTGRES_USER = env.DB_USERNAME;
          POSTGRES_DB = env.DB_DATABASE_NAME;
          POSTGRES_PASSWORD.fromFile = cfg.dbPasswordFile;
        };

        stack = name;
      };

      ${mlName} = {
        image = "ghcr.io/immich-app/immich-machine-learning:v1.143.0";
        volumes = ["${storage}/model-cache:/cache"];

        stack = name;
      };
    };
  };
}
