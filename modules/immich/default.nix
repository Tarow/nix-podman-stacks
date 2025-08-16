{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "immich";

  dbName = "${name}-db";
  redisName = "${name}-redis";
  mlName = "${name}-machine-learning";

  storage = "${config.nps.storageBaseDir}/${name}";
  mediaStorage = "${config.nps.mediaStorageBaseDir}";
  cfg = config.nps.stacks.${name};

  patchedConfigLocation = "/run/user/${toString config.nps.hostUid}/immmich/config_patched.json";
  configSource = if cfg.authelia.enable then patchedConfigLocation else cfg.settings;

  env = {
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

  json = pkgs.formats.json { };
in
{
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
      apply = settings: if (settings != null) then (json.generate "config.json" settings) else null;
    };
    authelia = {
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
    };
    dbPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the PostgreSQL password for the Immich database.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.userSchemas = {
      immich-quota.attributeType = "INTEGER";
      immich-role.attributeType = "STRING";
    };

    nps.stacks.authelia = lib.mkIf cfg.authelia.enable {
      settings.authentication_backend = {
        ldap.attributes.extra = {
          immich-quota = {
            name = "immich_quota";
            value_type = "integer";
          };
          immich-role = {
            name = "immich_role";
            value_type = "string";
          };
        };
        file.extraAttributes = {
          immich_quota = {
            multi_valued = false;
            value_type = "integer";
          };
          immich_role = {
            multi_valued = false;
            value_type = "string";
          };
        };
      };
      settings.identity_providers.oidc = {
        claims_policies.immich_policy.custom_claims = {
          immich_quota.attribute = "immich_quota";
          immich_role.attribute = "immich_role";
        };
        scopes.immich_scope.claims = [
          "immich_quota"
          "immich_role"
        ];
      };
      oidc.clients.${name} = {
        client_name = "Immich";
        client_secret = cfg.authelia.clientSecretHash;
        public = false;
        authorization_policy = "one_factor";
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = "1 month";
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceDomain}/auth/login"
          "${cfg.containers.${name}.traefik.serviceDomain}/user-settings"
          "app.immich:///oauth-callback"
        ];
        token_endpoint_auth_method = "client_secret_post";
        scopes = [
          "openid"
          "profile"
          "email"
          "immich_scope"
        ];
        claims_policy = "immich_policy";
      };
    };

    nps.stacks.${name}.settings =
      import ./config.nix
      // (lib.optionalAttrs cfg.authelia.enable {
        oauth = {
          enabled = true;
          autoLaunch = false;
          autoRegister = true;
          buttonText = "Login with Authelia";
          clientId = name;
          clientSecret = "";
          defaultStorageQuota = 0;
          issuerUrl = config.nps.stacks.authelia.containers.authelia.traefik.serviceDomain;
          mobileOverrideEnabled = false;
          mobileRedirectUri = "";
          scope = "openid profile email immich_scope";
          storageLabelClaim = "preferred_username";
          storageQuotaClaim = "immich_quota";
          roleClaim = "immich_role";
          timeout = 30000;
          tokenEndpointAuthMethod = "client_secret_post";
        };
      });

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/immich-app/immich-server:v1.137.3";
        volumes = [
          "${mediaStorage}/pictures/immich:${env.UPLOAD_LOCATION}"
        ]
        ++ lib.optional (cfg.settings != null) "${configSource}:${env.IMMICH_CONFIG_FILE}";

        environment = env;
        extraEnv.DB_PASSWORD.fromFile = cfg.dbPasswordFile;
        devices = [ "/dev/dri:/dev/dri" ];

        extraConfig.Service.ExecStartPre = lib.mkIf cfg.authelia.enable [
          (lib.getExe (
            pkgs.writeShellApplication {
              name = "patch_immich_config";
              runtimeInputs = [
                pkgs.jq
              ];
              text = ''
                install -D -m 600 /dev/null ${patchedConfigLocation}
                oauthClientSecret="$(<${cfg.authelia.clientSecretFile})"
                jq -c \
                  --arg oauthClientSecret "$oauthClientSecret" \
                  '.oauth.clientSecret = $oauthClientSecret' \
                  ${cfg.settings} > ${patchedConfigLocation}
              '';
            }
          ))
        ];

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
        volumes = [ "${storage}/pgdata:/var/lib/postgresql/data" ];

        extraEnv = {
          POSTGRES_USER = env.DB_USERNAME;
          POSTGRES_DB = env.DB_DATABASE_NAME;
          POSTGRES_PASSWORD.fromFile = cfg.dbPasswordFile;
        };

        stack = name;
      };

      ${mlName} = {
        image = "ghcr.io/immich-app/immich-machine-learning:v1.137.3";
        volumes = [ "${storage}/model-cache:/cache" ];

        stack = name;
      };
    };
  };
}
