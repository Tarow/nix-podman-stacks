{
  config,
  lib,
  ...
}: let
  name = "anchor";
  dbName = "${name}-db";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Offline-first note-taking Application";
  displayName = "Anchor";
in {
  imports = import ../mkAliases.nix config lib name [name dbName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          See <https://github.com/zhfahim/anchor?tab=readme-ov-file#oidc-authentication>
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };

    db = {
      type = lib.mkOption {
        type = lib.types.enum ["embedded" "postgres"];
        default = "embedded";
        description = "Type of database to use";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the PostgreSQL password.
          Only used when db.type is set to "postgres".
        '';
      };
    };

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        public = true;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/oidc/callback"
          "anchor://oidc/callback"
        ];
      };

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
        image = "ghcr.io/zhfahim/anchor:0.10.0";
        volumeMap.data = "${storage}/data:/data";

        extraEnv =
          {
            APP_URL = cfg.containers.${name}.traefik.serviceUrl;
          }
          // lib.optionalAttrs (cfg.db.type == "postgres") {
            PG_HOST = dbName;
            PG_PORT = 5432;
            PG_USER = name;
            PG_PASSWORD.fromFile = cfg.db.passwordFile;
            PG_DATABASE = name;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            OIDC_ENABLED = true;
            OIDC_PROVIDER_NAME = "Authelia";
            OIDC_ISSUER_URL = config.nps.containers.authelia.traefik.serviceUrl;
            OIDC_CLIENT_ID = name;
            DISABLE_INTERNAL_AUTH = lib.mkDefault true;
            USER_SIGNUP = lib.mkDefault "disabled";
          }
          // cfg.extraEnv;

        wantsContainer = lib.optional (cfg.db.type == "postgres") dbName;
        stack = name;

        port = 3000;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "anchor";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:anchor";
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
