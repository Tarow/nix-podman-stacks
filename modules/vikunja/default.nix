{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "vikunja";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};

  category = "General";
  description = "To-Dos";
  displayName = "Vikunja";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the JWT secret.

        See <https://vikunja.io/docs/config-options/#1-service-JWTSecret>
      '';
    };
    settings = lib.mkOption {
      type = yaml.type;
      default = {};
      description = ''
        Extra settings being provided as the `/etc/vikunja/config.yml` file.

        See <https://vikunja.io/docs/config-options>
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

          - <https://www.authelia.com/integration/openid-connect/clients/vikunja/>
          - <https://vikunja.io/docs/openid/>
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
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
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
      username = lib.mkOption {
        type = lib.types.str;
        default = "vikunja";
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
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Vikunja";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/auth/openid/authelia"
        ];
      };

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level.
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

    nps.stacks.${name}.settings = lib.mkIf cfg.oidc.enable {
      auth.openid = {
        enabled = true;
        providers.authelia = {
          name = "Authelia";
          authurl = config.nps.containers.authelia.traefik.serviceUrl;
          clientid = name;
          scope = "openid profile email";
          forceuserinfo = true;
        };
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "docker.io/vikunja/vikunja:1.0.0-rc1";
        user = config.nps.defaultUid;
        volumes =
          [
            "${storage}/files:/app/vikunja/files"
            "${yaml.generate "config.yml" cfg.settings}:/etc/vikunja/config.yml"
          ]
          ++ lib.optional (cfg.db.type == "sqlite") "${storage}/sqlite:/db";

        extraEnv =
          {
            VIKUNJA_SERVICE_PUBLICURL = cfg.containers.${name}.traefik.serviceUrl;
            VIKUNJA_SERVICE_JWTSECRET.fromFile = cfg.jwtSecretFile;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHELIA_CLIENTSECRET.fromFile = cfg.oidc.clientSecretFile;
          }
          // lib.optionalAttrs (cfg.db.type == "sqlite") {
            VIKUNJA_DATABASE_PATH = "/db/vikunja.db";
          }
          // lib.optionalAttrs (cfg.db.type == "postgres") {
            VIKUNJA_DATABASE_HOST = dbName;
            VIKUNJA_DATABASE_USER = cfg.db.username;
            VIKUNJA_DATABASE_PASSWORD.fromFile = cfg.db.passwordFile;
            VIKUNJA_DATABASE_TYPE = "postgres";
            VIKUNJA_DATABASE_DATABASE = "vikunja";
          };

        dependsOnContainer = lib.optional (cfg.db.type == "postgres") dbName;
        stack = name;
        port = 3456;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "vikunja";
            widget.type = "vikunja";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:vikunja";
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:17";
        volumes = ["${storage}/postgres:/var/lib/postgresql/data"];
        extraEnv = {
          POSTGRES_DB = "vikunja";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
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
