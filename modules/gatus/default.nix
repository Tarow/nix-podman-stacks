{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "gatus";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml { };
in
{
  imports = [
    ./extension.nix
  ]
  ++ import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name // {
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
        To see all valid settings, refer to the projects documentation: <https://github.com/TwiN/gatus>
      '';
    };
    extraSettingsFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
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
    authelia = {
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
      allowedSubjects = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          List of allowed subjects. If not set, all subjects will be allowed.
        '';
      };
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = { };
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
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the `postgresPasswordFile` option must be set.
        '';
      };
      postgresUser = lib.mkOption {
        type = lib.types.str;
        default = "gatus";
        description = ''
          The PostgreSQL user to use for the database.
          Only used if db.type is set to "postgres".
        '';
      };
      postgresPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the PostgreSQL password for the database.
          Only used if db.type is set to "postgres".
        '';
      };

    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.authelia = lib.mkIf cfg.authelia.enable {
      oidc.clients.${name} = {
        client_name = "Gatus";
        client_secret = cfg.authelia.clientSecretHash;
        public = false;
        authorization_policy = "one_factor";
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = "1 month";
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceDomain}/authorization-code/callback"
        ];
      };
    };

    nps.stacks.${name}.settings = {
      storage = {
        type = cfg.db.type;
        path =
          if (cfg.db.type == "sqlite") then
            "/data/data.db"
          else
            "postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@${dbName}:5432/${
              cfg.containers.${dbName}.environment.POSTGRES_DB
            }?sslmode=disable";
      };
      security = lib.mkIf cfg.authelia.enable {
        oidc =
          let
            authelia = config.nps.stacks.authelia;
            oidcClient = authelia.oidc.clients.${name};
          in
          {
            issuer-url = authelia.containers.authelia.traefik.serviceDomain;
            client-id = oidcClient.client_id;
            client-secret = "\${AUTHELIA_CLIENT_SECRET}";
            redirect-url = lib.elemAt oidcClient.redirect_uris 0;
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            allowed-subjects = cfg.authelia.allowedSubjects;
          };
      };
    };

    services.podman.containers = {
      ${name} =
        let
          settings = cfg.settings // {
            endpoints = lib.map (e: lib.recursiveUpdate cfg.defaultEndpoint e) (cfg.settings.endpoints or [ ]);
          };
          configDir = "/app/config";
        in
        {
          image = "ghcr.io/twin/gatus:v5.23.2";
          volumes = [
            "${yaml.generate "config.yml" settings}:${configDir}/config.yml"
          ]
          ++ (lib.map (f: "${f}:${configDir}/${builtins.baseNameOf f}") cfg.extraSettingsFiles)
          ++ lib.optional (cfg.db.type == "sqlite") "${storage}/sqlite:/data";
          environment = {
            GATUS_CONFIG_PATH = configDir;
          };
          extraEnv = {
            AUTHELIA_CLIENT_SECRET.fromFile = cfg.authelia.clientSecretFile;
          }
          // lib.optionalAttrs (cfg.db.type == "postgres") {
            POSTGRES_USER = cfg.db.postgresUser;
            POSTGRES_PASSWORD.fromFile = cfg.db.postgresPasswordFile;
          }
          // cfg.extraEnv;

          stack = name;
          port = 8080;
          traefik.name = name;
          homepage = {
            category = "Monitoring";
            name = "Gatus";
            settings = {
              description = "Health Monitoring";
              icon = "gatus";
              widget.type = "gatus";
            };
          };
        };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:17";
        volumes = [ "${storage}/postgres:/var/lib/postgresql/data" ];
        extraEnv = {
          POSTGRES_DB = "gatus";
          POSTGRES_USER = cfg.db.postgresUser;
          POSTGRES_PASSWORD.fromFile = cfg.db.postgresPasswordFile;
        };

        stack = name;
      };
    };
  };
}
