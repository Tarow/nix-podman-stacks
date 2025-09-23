{
  config,
  lib,
  ...
}: let
  name = "guacamole";
  guacdName = "guacd";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Network & Administration";
  description = "Remote Access Gateway";
  displayName = "Guacamole";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    userMappingXml = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to file that is provided as the `user-mapping.xml`.

        See <https://guacamole.apache.org/doc/gug/configuring-guacamole.html#user-mapping-xml>
      '';
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          When OIDC is enabled, the `db.passwordFile` option has to be provided, as a DB setup is required for OIDC to work.
          Users from the `user-mapping.xml` won't be matched when logging in via OIDC.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/apache-guacamole/>
          - <https://guacamole.apache.org/doc/gug/openid-auth.html>
        '';
      };
    };
    db = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.oidc.enable;
        description = ''
          Whether to use a DB for authentication.
          This is required when OIDC is enabled.

          See <https://guacamole.apache.org/doc/gug/jdbc-auth.html#database-authentication>
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "guacamole";
        description = ''
          The PostgreSQL user to use for the database.
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the PostgreSQL password for the database.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.oidc.enable || cfg.db.enable;
        message = "Guacamole: when OIDC is enabled, the database option must also be enabled.";
      }
    ];

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Guacamole";
        public = true;
        authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          cfg.containers.${name}.traefik.serviceUrl
        ];
        response_types = "id_token";
        grant_types = "implicit";
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "docker.io/guacamole/guacamole:1.6.0";
        user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
        environment = {
          GUACD_HOSTNAME = guacdName;
          WEBAPP_CONTEXT = "ROOT";
        };
        volumes = lib.optional (cfg.userMappingXml != null) "${cfg.userMappingXml}:/etc/guacamole/user-mapping.xml";

        extraEnv = let
          autheliaUrl = config.nps.containers.authelia.traefik.serviceUrl;
        in
          lib.optionalAttrs (cfg.oidc.enable) {
            OPENID_ENABLED = cfg.oidc.enable;
            OPENID_CLIENT_ID = name;
            OPENID_SCOPE = ''\"openid profile groups email\"'';
            OPENID_ISSUER = autheliaUrl;
            OPENID_JWKS_ENDPOINT = "${autheliaUrl}/jwks.json";
            OPENID_AUTHORIZATION_ENDPOINT = "${autheliaUrl}/api/oidc/authorization?state=1234abcedfdhf";
            OPENID_REDIRECT_URI = cfg.containers.${name}.traefik.serviceUrl;
            OPENID_USERNAME_CLAIM_TYPE = "preferred_username";
            OPENID_GROUPS_CLAIM_TYPE = "groups";
            EXTENSION_PRIORITY = ''\"*, openid\"'';
          }
          // lib.optionalAttrs (cfg.db.enable) {
            POSTGRESQL_DATABASE = name;
            POSTGRESQL_HOSTNAME = dbName;
            POSTGRESQL_PASSWORD.fromFile = cfg.db.passwordFile;
            POSTGRESQL_USERNAME = cfg.db.username;
          };

        wantsContainer = [guacdName] ++ (lib.optional cfg.db.enable dbName);

        stack = name;
        port = 8080;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "guacamole";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:guacamole";
        };
      };

      ${guacdName} = {
        image = "docker.io/guacamole/guacd:1.6.0";

        stack = name;
      };

      ${dbName} = lib.mkIf cfg.db.enable {
        image = "docker.io/postgres:17";
        volumes = [
          "${storage}/postgres:/var/lib/postgresql/data"
          "${./initdb.sql}:/docker-entrypoint-initdb.d/initdb.sql"
        ];
        extraEnv = {
          POSTGRES_DB = name;
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        stack = name;
        glance = {
          inherit category;
          parent = name;
          icon = "di:postgres";
        };
      };
    };
  };
}
