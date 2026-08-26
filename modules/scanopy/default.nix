{
  config,
  lib,
  ...
}: let
  name = "scanopy";
  daemonName = "${name}-daemon";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  serverPort = 60072;
  daemonPort = 60073;

  category = "Network & Administration";
  description = "Network Documentation & Topology Mapping";
  displayName = "Scanopy";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    daemonName
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          Scanopy links OIDC logins to existing accounts and does not support role mapping based
          on groups, so access is restricted on Authelia level to the user group.
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
        default = name;
        description = "The PostgreSQL user to use for the database";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "The file containing the PostgreSQL password for the database";
      };
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the server and daemon containers.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://scanopy.net/docs/reference/server-configuration/>
      '';
      example = {
        SCANOPY_DISABLE_REGISTRATION = true;
        SCANOPY_LOG_LEVEL = "debug";
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
        scopes = ["openid" "email" "profile"];
        response_types = ["code"];
        grant_types = ["authorization_code"];
        access_token_signed_response_alg = "none";
        userinfo_signed_response_alg = "none";
        token_endpoint_auth_method = "client_secret_basic";
        consent_mode = "auto";
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/oidc/authelia/callback"
        ];
      };

      # No role mapping based on groups. Restrict access on Authelia level for now
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
        image = "ghcr.io/scanopy/scanopy/server:v0.17.13";
        volumeMap.data = "${storage}/data:/data";

        extraEnv =
          {
            SCANOPY_DATABASE_URL.fromTemplate = "postgresql://${cfg.db.username}:{{ file.Read \"${cfg.db.passwordFile}\" }}@${dbName}:5432/scanopy";
            SCANOPY_PUBLIC_URL = cfg.containers.${name}.traefik.serviceUrl;
            SCANOPY_WEB_EXTERNAL_PATH = "/app/static";
            SCANOPY_USE_SECURE_SESSION_COOKIES = true;
            SCANOPY_INTEGRATED_DAEMON_URL = "http://host.containers.internal:${toString daemonPort}";
          }
          // lib.optionalAttrs cfg.oidc.enable {
            SCANOPY_OIDC_PROVIDERS.fromTemplate = ''
              [{name="Authelia",slug="authelia",issuer_url="${config.nps.containers.authelia.traefik.serviceUrl}",client_id="${name}",client_secret="{{ file.Read "${cfg.oidc.clientSecretFile}" }}"}]
            '';
          }
          // cfg.extraEnv;

        stack = name;
        port = serverPort;
        traefik.name = name;

        wantsContainer = [dbName];

        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "scanopy";
          };
        };

        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:scanopy";
        };
      };

      ${daemonName} = {
        image = "ghcr.io/scanopy/scanopy/daemon:v0.17.13";

        volumeMap = {
          config = "${storage}/daemon:/root/.config";
          podman-socket = "${config.nps.socketLocation}:/var/run/podman.sock:ro";
        };

        network = ["host"];
        addCapabilities = ["NET_RAW" "NET_ADMIN"];

        dependsOn = ["podman.socket"];

        extraEnv =
          {
            SCANOPY_SERVER_URL = cfg.containers.${name}.traefik.serviceUrl;
            CONTAINER_HOST = "unix:///var/run/podman.sock";
          }
          // cfg.extraEnv;

        glance = {
          inherit category;
          parent = name;
          name = "Daemon";
          icon = "di:scanopy";
        };
      };

      ${dbName} = {
        image = "docker.io/postgres:18";
        stack = name;
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";
        extraEnv = {
          POSTGRES_DB = name;
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

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
