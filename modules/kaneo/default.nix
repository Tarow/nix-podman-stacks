{
  config,
  lib,
  ...
}: let
  name = "kaneo";
  webName = "${name}-web";
  apiName = "${name}-api";
  dbName = "${name}-db";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Project Management";
  displayName = "Kaneo";
in {
  imports = import ../mkAliases.nix config lib name [
    webName
    apiName
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    authSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the auth secret.
        You can generate a secret using `openssl rand -hex 32`.

        See <https://kaneo.app/docs/core/installation/environment-variables#authentication>
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
          - <https://kaneo.app/docs/core/social-providers/custom-oauth>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = ''
          Users of this group will be able to log in
        '';
      };
    };
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "kaneo";
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
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${apiName}.traefik.serviceUrl}/api/auth/oauth2/callback/custom"
        ];
        token_endpoint_auth_method = "client_secret_post";
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
      ${webName} = {
        image = "ghcr.io/usekaneo/web:2.3.7";

        environment = {
          KANEO_CLIENT_URL = cfg.containers.${webName}.traefik.serviceUrl;
          KANEO_API_URL = cfg.containers.${apiName}.traefik.serviceUrl;
        };

        wantsContainer = [apiName];

        stack = name;
        port = 5173;
        traefik.name = name;

        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "sh-kaneo";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = webName;
          icon = "sh:kaneo";
        };
      };

      ${apiName} = {
        image = "ghcr.io/usekaneo/api:2.3.7";

        extraEnv =
          {
            AUTH_SECRET.fromFile = cfg.authSecretFile;
            KANEO_CLIENT_URL = cfg.containers.${webName}.traefik.serviceUrl;
            KANEO_API_URL = cfg.containers.${apiName}.traefik.serviceUrl;
            DATABASE_URL.fromTemplate = "postgres://${cfg.db.username}:{{ file.Read `${cfg.db.passwordFile}` }}@${dbName}/${name}";
            DISABLE_GUEST_ACCESS = lib.mkDefault true;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            CUSTOM_OAUTH_CLIENT_ID = name;
            CUSTOM_OAUTH_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            CUSTOM_OAUTH_DISCOVERY_URL = "${config.nps.containers.authelia.traefik.serviceUrl}/.well-known/openid-configuration";
            CUSTOM_OAUTH_SCOPES = "openid,profile,email";
          };

        wantsContainer = [dbName];
        stack = name;

        traefik.name = apiName;

        glance = {
          inherit category;
          name = "Backend";
          parent = name;
          icon = "sh:kaneo";
        };
      };

      ${dbName} = {
        image = "docker.io/postgres:18";
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";

        extraEnv = {
          POSTGRES_DB = name;
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -d ${name} -U ${cfg.db.username}";
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
