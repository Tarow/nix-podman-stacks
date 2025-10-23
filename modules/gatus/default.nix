{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "gatus";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};

  category = "Monitoring";
  description = "Health Monitoring";
  displayName = "Gatus";
in {
  imports =
    [
      ./extension.nix
    ]
    ++ import ../mkAliases.nix config lib name [
      name
      dbName
    ];

  options.nps.stacks.${name} = {
    enable =
      lib.mkEnableOption name
      // {
        description = ''
          Whether to enable Gatus.
          The module also provides an extension that will add Gatus options to a container.
          This allows services to be added to Gatus by settings container options.
        '';
      };
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Settings for the Gatus container.
        Will be converted to YAML and passed to the container.

        See <https://github.com/TwiN/gatus>
      '';
    };
    extraSettingsFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        List of additional YAML files to include in the settings.
        These files will be mounted as is. Can be used to directly provide YAML files containing secrets, e.g. from sops
      '';
    };
    defaultEndpoint = lib.mkOption {
      type = yaml.type;
      default = {
        group = "core";
        interval = "5m";
        client = {
          insecure = true;
          timeout = "10s";
        };
        conditions = [
          "[STATUS] >= 200"
          "[STATUS] < 300"
        ];
      };
      description = ''
        Default endpoint settings. Will merged with each provided endpoint.
        Only applies if endpoint does not override the default endpoint settings.
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

          - <https://www.authelia.com/integration/openid-connect/clients/gatus/>
          - <https://github.com/TwiN/gatus?tab=readme-ov-file#oidc>
        '';
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          The file containing the client secret for the Gatus OIDC client that will be registered in Authelia.
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
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/TwiN/gatus?tab=readme-ov-file#configuration>
      '';
      example = {
        SOME_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        FOO = "bar";
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
        default = "gatus";
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
        client_name = "Gatus";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/authorization-code/callback"
        ];
      };

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
      # See <https://github.com/TwiN/gatus/issues/638>
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

    nps.stacks.${name}.settings = {
      storage = {
        type = cfg.db.type;
        path =
          if (cfg.db.type == "sqlite")
          then "/data/data.db"
          else "postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@${dbName}:5432/${
            cfg.containers.${dbName}.environment.POSTGRES_DB
          }?sslmode=disable";
      };
      security = lib.mkIf cfg.oidc.enable {
        oidc = let
          authelia = config.nps.stacks.authelia;
          oidcClient = authelia.oidc.clients.${name};
        in {
          issuer-url = authelia.containers.authelia.traefik.serviceUrl;
          client-id = oidcClient.client_id;
          client-secret = "\${AUTHELIA_CLIENT_SECRET}";
          redirect-url = lib.elemAt oidcClient.redirect_uris 0;
          scopes = [
            "openid"
            "profile"
            "email"
          ];
        };
      };
    };

    services.podman.containers = {
      ${name} = let
        settings =
          cfg.settings
          // {
            endpoints = lib.map (e: lib.recursiveUpdate cfg.defaultEndpoint e) (cfg.settings.endpoints or []);
          };
        configDir = "/app/config";
      in {
        image = "ghcr.io/twin/gatus:v5.28.0";
        volumes =
          [
            "${yaml.generate "config.yml" settings}:${configDir}/config.yml"
          ]
          ++ (lib.map (f: "${f}:${configDir}/${builtins.baseNameOf f}") cfg.extraSettingsFiles)
          ++ lib.optional (cfg.db.type == "sqlite") "${storage}/sqlite:/data";
        environment = {
          GATUS_CONFIG_PATH = configDir;
        };
        extraEnv =
          lib.optionalAttrs cfg.oidc.enable {
            AUTHELIA_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          }
          // lib.optionalAttrs (cfg.db.type == "postgres") {
            POSTGRES_USER = cfg.db.username;
            POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
          }
          // cfg.extraEnv;

        addCapabilities = [
          "NET_RAW"
        ];

        dependsOnContainer = lib.optional (cfg.db.type == "postgres") dbName;
        stack = name;
        port = 8080;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "gatus";
            widget.type = "gatus";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:gatus";
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:17";
        volumes = ["${storage}/postgres:/var/lib/postgresql/data"];
        extraEnv = {
          POSTGRES_DB = "gatus";
          POSTGRES_USER = cfg.db.username;
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
