{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "gatus";
  dbName = "${name}-db";
  cfg = config.tarow.podman.stacks.${name};
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
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

  options.tarow.podman.stacks.${name} = {
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
      clientSecretEnvName = lib.mkOption {
        type = lib.types.str;
        description = ''
          Name of the environment variable that contains the client_secret.
          You will have to provide a variable with the given name in the `env_file` option.

          E.g. when setting `clientSecretEnvName = AUTHELIA_CLIENT_SECRET`, then the `envFile` should be a file containing the variable:
          ```env
          AUTHELIA_CLIENT_SECRET=some_secret
          ```
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
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the environment file for the container.
        Can be used to e.g. pass secrets that are referenced in the settings.
      '';
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
          If set to "postgres", the envFile option must be set.
        '';
      };
      envFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the environment file for the database.
          Required if db.type is set to "postgres".
          Must contain the environment variables 'POSTGRES_USER', and 'POSTGRES_PASSWORD'.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.authelia = lib.mkIf cfg.authelia.enable {
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

    tarow.podman.stacks.${name}.settings = {
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
            authelia = config.tarow.podman.stacks.authelia;
            oidcClient = authelia.oidc.clients.${name};
          in
          {
            issuer-url = authelia.containers.authelia.traefik.serviceDomain;
            client-id = oidcClient.client_id;
            client-secret = "\${${cfg.authelia.clientSecretEnvName}}";
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
          image = "ghcr.io/twin/gatus:v5.22.0";
          volumes = [
            "${yaml.generate "config.yml" settings}:${configDir}/config.yml"
          ]
          ++ (lib.map (f: "${f}:${configDir}/${builtins.baseNameOf f}") cfg.extraSettingsFiles)
          ++ lib.optional (cfg.db.type == "sqlite") "${storage}/sqlite:/data";
          environment = {
            GATUS_CONFIG_PATH = configDir;
          };
          environmentFile =
            (lib.optional (cfg.envFile != null) cfg.envFile)
            ++ (lib.optional (cfg.db.type == "postgres") cfg.db.envFile);

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
        environment = {
          POSTGRES_DB = "gatus";
        };
        environmentFile = [ cfg.db.envFile ];

        stack = name;
      };
    };
  };
}
