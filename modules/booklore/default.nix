{
  config,
  lib,
  ...
}: let
  name = "booklore";
  dbName = "${name}-db";

  storage = "${config.nps.storageBaseDir}/${name}";

  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Book Collection Manager";
  displayName = "booklore";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    oidc = {
      registerClient = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to register a Booklore OIDC client in Authelia.
          To enable OIDC Login for Booklore, you will have to enable it in the Web UI.

          For details, see:
          - <https://www.authelia.com/integration/openid-connect/clients/booklore/>
          - <https://booklore-app.github.io/booklore-docs/docs/authentication/authelia>
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };
    db = {
      userPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the romm database user";
      };
      rootPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the MariaDB root user";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.registerClient {
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.registerClient {
      oidc.clients.${name} = {
        client_name = "Booklore";
        public = true;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/oauth2-callback"
        ];
        scopes = ["openid" "offline_access" "profile" "email"];
        claims_policy = name;
        response_types = ["code"];
        grant_types = ["authorization_code" "refresh_token"];
      };

      settings.identity_providers.oidc.cors = {
        allowed_origins = "*";
        endpoints = [
          "authorization"
          "pushed-authorization-request"
          "token"
          "revocation"
          "introspection"
          "userinfo"
        ];
      };
      # See <https://www.authelia.com/integration/openid-connect/clients/booklore/#configuration-escape-hatch>
      settings.identity_providers.oidc.claims_policies.${name}.id_token = [
        "email"
        "email_verified"
        "preferred_username"
        "name"
      ];

      # Booklore doesn't support blocking access to users that aren't part of a group, so we have to do it on Authelia level
      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = [
              "group:${cfg.oidc.userGroup}"
            ];
          }
        ];
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/booklore-app/booklore:v1.10.0";
        volumes = [
          "${storage}/data:/data"
          "${storage}/books:/books"
          "${storage}/bookdrop:/bookdrop"
        ];

        extraEnv = let
          db = cfg.containers.${dbName}.extraEnv;
        in {
          USER_ID = config.nps.defaultUid;
          GROUP_ID = config.nps.defaultGid;
          DATABASE_URL.fromTemplate = "jdbc:mariadb://${dbName}:3306/${db.MARIADB_DATABASE}";
          DATABASE_USERNAME = db.MARIADB_USER;
          DATABASE_PASSWORD = db.MARIADB_PASSWORD;
          BOOKLORE_PORT = 6060;
        };

        dependsOnContainer = [dbName];
        stack = name;

        port = 6060;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "sh-booklore";
            widget.type = "booklore";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "sh:booklore";
        };
      };
      ${dbName} = {
        image = "docker.io/mariadb:11";
        volumes = ["${storage}/db:/var/lib/mysql"];
        extraEnv = {
          MARIADB_DATABASE = "booklore";
          MARIADB_USER = "booklore";
          MARIADB_ROOT_PASSWORD.fromFile = cfg.db.rootPasswordFile;
          MARIADB_PASSWORD.fromFile = cfg.db.userPasswordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "healthcheck.sh --connect --innodb_initialized";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "20s";
        };

        stack = name;
        glance = {
          parent = name;
          name = "MariaDB";
          icon = "si:mariadb";
          inherit category;
        };
      };
    };
  };
}
