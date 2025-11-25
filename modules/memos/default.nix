{
  config,
  lib,
  ...
}: let
  name = "memos";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Knowledge Management";
  displayName = "Memos";
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
          Whether to register an OIDC client in Authelia.
          If enabled you need to provide a hashed secret in the `client_secret` option.

          To enable OIDC Login for Memos, you will have to configure it in the Web UI.

          For details, see:
          - <https://www.authelia.com/integration/openid-connect/clients/memos/>
          - <https://www.usememos.com/docs/configuration/authentication#oauth-sso-providers>
        '';
      };
      clientSecretHash = lib.mkOption {
        type = lib.types.str;
        description = ''
          The hashed client_secret.
          For examples on how to generate a client secret, see

          <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = ''
          Users of this group will be able to log in
        '';
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
        default = "memos";
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
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.registerClient {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.registerClient {
      oidc.clients.${name} = {
        client_name = "Memos";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/auth/callback"
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
      ${name} = {
        image = "ghcr.io/usememos/memos:0.25.3";
        volumes = ["${storage}/data:/var/opt/memos"];
        environment = {
          MEMOS_MODE = "prod";
          MEMOS_PORT = 5230;
        };
        extraEnv = lib.optionalAttrs (cfg.db.type == "postgres") {
          MEMOS_DRIVER = "postgres";
          MEMOS_DSN.fromTemplate = "postgres://${cfg.db.username}:{{ file.Read `${cfg.db.passwordFile}` }}@${dbName}/memos?sslmode=disable";
        };

        dependsOnContainer = lib.optional (cfg.db.type == "postgres") dbName;
        stack = name;
        port = 5230;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "memos";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:memos";
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:17";
        volumes = ["${storage}/postgres:/var/lib/postgresql/data"];
        extraEnv = {
          POSTGRES_DB = "memos";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
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
