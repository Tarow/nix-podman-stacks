{
  config,
  lib,
  ...
}: let
  name = "leantime";
  dbName = "${name}-db";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Project Management";
  displayName = "Leantime";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    sessionPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the session password.
        Can be generated using `openssl rand -hex 32`
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See
        - <https://docs.leantime.io/installation/configuration>
        - <https://github.com/Leantime/docker-leantime/blob/master/sample.env>
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
          - <https://www.authelia.com/integration/openid-connect/clients/leantime/>
          - <https://docs.leantime.io/installation/configuration?id=openid-conenct-oidc-configuration>
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
        default = "leantime";
        description = "Username for the database user.";
      };
      userPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the database user.";
      };
      rootPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the root user.";
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
          "${cfg.containers.${name}.traefik.serviceUrl}/oidc/callback"
        ];
        token_endpoint_auth_method = "client_secret_post";
        claims_policy = name;
      };

      settings.identity_providers.oidc.claims_policies.${name}.id_token = [
        "email"
        "email_verified"
        "preferred_username"
        "name"
      ];

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
        image = "docker.io/leantime/leantime:latest";

        volumeMap = {
          publicUserfile = "${storage}/userfiles:/var/www/html/public/userfiles";
          userfile = "${storage}/userfiles:/var/www/html/userfiles";
          plugins = "${storage}/config:/var/www/html/app/Plugins";
          logs = "${storage}/logs:/var/www/html/storage/logs";
        };

        # Seems like Leantime will always run as 1000:1000, map user to avoid permission issues for now
        # https://github.com/Leantime/leantime/issues/3134
        user = "0:0";
        extraConfig.Container.UserNS = "keep-id:uid=1000,gid=1000";

        extraEnv = let
          db = cfg.containers.${dbName}.extraEnv;
        in
          {
            PUID = config.nps.defaultUid;
            PGID = config.nps.defaultGid;

            LEAN_SESSION_PASSWORD.fromFile = cfg.sessionPasswordFile;
            LEAN_APP_URL = cfg.containers.${name}.traefik.serviceUrl;
            LEAN_ALLOW_TELEMETRY = false;
            LEAN_SESSION_SECURE = true;

            LEAN_DB_HOST = dbName;
            LEAN_DB_USER = db.MYSQL_USER;
            LEAN_DB_PASSWORD = db.MYSQL_PASSWORD;
            LEAN_DB_DATABASE = db.MYSQL_DATABASE;
            LEAN_DB_PORT = 3306;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            LEAN_OIDC_ENABLE = true;
            LEAN_OIDC_CLIENT_ID = name;
            LEAN_OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            LEAN_OIDC_PROVIDER_URL = config.nps.containers.authelia.traefik.serviceUrl;
            LEAN_OIDC_CREATE_USER = true;
            LEAN_OIDC_DEFAULT_ROLE = 20; # Editor
          };

        stack = name;
        port = 8080;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "leantime";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:leantime";
        };
      };

      ${dbName} = {
        image = "docker.io/mariadb:12";
        volumeMap.data = "${storage}/db:/var/lib/mysql";
        extraEnv = {
          MYSQL_DATABASE = "leantime";
          MYSQL_USER = cfg.db.username;
          MYSQL_PASSWORD.fromFile = cfg.db.userPasswordFile;
          MYSQL_ROOT_PASSWORD.fromFile = cfg.db.rootPasswordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "healthcheck.sh --connect --innodb_initialized";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "20s";
          HealthOnFailure = "kill";
        };

        stack = name;

        glance = {
          inherit category;
          parent = name;
          name = "MariaDB";
          icon = "di:mariadb";
        };
      };
    };
  };
}
