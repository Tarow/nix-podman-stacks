{
  config,
  lib,
  ...
}: let
  name = "homebox";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Inventory and Organization System";
  displayName = "HomeBox";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://homebox.software/en/quick-start/configure/#env-variables--configuration>
      '';
    };
    db = {
      type = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
        default = "sqlite";
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the `passwordFile` option must be set.
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
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:
          - <https://www.authelia.com/integration/openid-connect/clients/homebox/>
          - <https://homebox.software/en/quick-start/configure/oidc/>
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
        authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/v1/users/login/oidc/callback"
        ];
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/sysadminsmedia/homebox:0.24.2";
        volumeMap.data = "${storage}/data:/data";

        extraEnv =
          {
            HBOX_WEB_PORT = 7745;
            HBOX_MODE = "production";
            HBOX_LOG_LEVEL = "info";
            HBOX_LOG_FORMAT = "text";
            HBOX_WEB_MAX_UPLOAD_SIZE = 10;
            HBOX_OPTIONS_ALLOW_ANALYTICS = false;
          }
          // lib.optionalAttrs (cfg.db.type == "postgres") {
            HBOX_DATABASE_DRIVER = "postgres";
            HBOX_DATABASE_HOST = dbName;
            HBOX_DATABASE_PORT = 5432;
            HBOX_DATABASE_USERNAME = name;
            HBOX_DATABASE_PASSWORD.fromFile = cfg.db.passwordFile;
            HBOX_DATABASE_DATABASE = name;
            HBOX_DATABASE_SSL_MODE = "disable";
          }
          // lib.optionalAttrs cfg.oidc.enable (let
            utils = import ../utils.nix {inherit lib config;};
          in {
            HBOX_OIDC_ENABLED = true;
            HBOX_OIDC_ISSUER_URL = config.nps.containers.authelia.traefik.serviceUrl;
            HBOX_OIDC_CLIENT_ID = name;
            HBOX_OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            HBOX_OPTIONS_TRUST_PROXY = true;
            HBOX_OPTIONS_HOSTNAME = cfg.containers.${name}.traefik.serviceHost;
            HBOX_OIDC_SCOPE = utils.escapeOnDemand ''"openid groups email profile"'';
            HBOX_OIDC_ALLOWED_GROUPS = cfg.oidc.userGroup;
            HBOX_OPTIONS_ALLOW_LOCAL_LOGIN = lib.mkDefault false;
            HBOX_OPTIONS_ALLOW_REGISTRATION = lib.mkDefault false;
          });

        # Authelia is necessary when Homebox starts as well-known endpoint is queried at startup
        wantsContainer = ["authelia"] ++ lib.optional (cfg.db.type == "postgres") dbName;

        port = 7745;
        traefik.name = name;
        stack = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "homebox";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:homebox";
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:18";
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";
        extraEnv = {
          POSTGRES_DB = name;
          POSTGRES_USER = name;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        stack = name;
        glance = {
          inherit category;
          parent = name;
          name = "Postgres";
          icon = "di:postgres";
        };
      };
    };
  };
}
