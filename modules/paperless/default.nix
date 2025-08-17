{
  config,
  lib,
  options,
  ...
}: let
  name = "paperless";
  dbName = "${name}-db";
  brokerName = "${name}-broker";
  ftpName = "${name}-ftp";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
    brokerName
    ftpName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    env = lib.mkOption {
      type = (options.services.podman.containers.type.getSubOptions []).environment.type;
      default = {};
      description = "Additional environment variables passed to the Paperless container";
    };
    envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the environment file containing the 'PAPERLESS_DBUSER' 'PAPERLESS_DBPASS' and 'PAPERLESS_SECRET_KEY' variables.
      '';
    };
    db.envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the env file containing the 'POSTGRES_USER' and 'POSTGRES_PASSWORD' variables
      '';
    };
    ftp = {
      enable =
        lib.mkEnableOption "FTP server"
        // {
          default = true;
        };
      envFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the env file containing the 'FTP_PASS' variable.
          Uploads to the FTP will be placed in the 'consume' directory to be ingested by Paperless.
        '';
      };
    };
    authelia = {
      registerClient = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to register a Paperless OIDC client in Authelia.
          If enabled you need to provide a hashed secret in the `client_secret` option.

          To enable OIDC Login for Paperless, you will have to provide the environment variables `PAPERLESS_APPS` and `PAPERLESS_SOCIALACCOUNT_PROVIDERS`,
          e.g. in the `envFile` option.

          For details, see:
          - <https://www.authelia.com/integration/openid-connect/clients/paperless/>
          - <https://docs.paperless-ngx.com/advanced_usage/#openid-connect-and-social-authentication>
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
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.authelia.oidc.clients.${name} = lib.mkIf cfg.authelia.registerClient {
      client_name = "Paperless";
      client_secret = cfg.authelia.clientSecretHash;
      public = false;
      authorization_policy = "one_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";
      pre_configured_consent_duration = "1 month";
      redirect_uris = [
        "${cfg.containers.${name}.traefik.serviceDomain}/accounts/oidc/authelia/login/callback/"
      ];
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:2.18.1";
        dependsOnContainer = [
          dbName
          brokerName
        ];
        volumes = [
          "${storage}/data:/usr/src/paperless/data"
          "${storage}/media:/usr/src/paperless/media"
          "${storage}/export:/usr/src/paperless/export"
          "${storage}/consume:/usr/src/paperless/consume"
        ];
        environment =
          {
            PAPERLESS_REDIS = "redis://${brokerName}:6379";
            PAPERLESS_DBHOST = dbName;
            USERMAP_UID = config.nps.defaultUid;
            USERMAP_GID = config.nps.defaultGid;
            PAPERLESS_TIME_ZONE = config.nps.defaultTz;
            PAPERLESS_FILENAME_FORMAT = "{{created_year}}/{{correspondent}}/{{title}}";
            PAPERLESS_URL = config.services.podman.containers.${name}.traefik.serviceDomain;
          }
          // cfg.env;

        environmentFile = [cfg.envFile];
        port = 8000;

        stack = name;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Paperless-ngx";
          settings = {
            description = "Document Management System";
            icon = "paperless-ngx";
            widget.type = "paperlessngx";
          };
        };
      };

      ${brokerName} = {
        image = "docker.io/redis:8.0";
        stack = name;
      };

      ${dbName} = {
        image = "docker.io/postgres:16";
        volumes = ["${storage}/db:/var/lib/postgresql/data"];
        environment = {
          POSTGRES_DB = "paperless";
        };
        environmentFile = [cfg.db.envFile];

        stack = name;
      };

      ${ftpName} = let
        uid = config.nps.defaultUid;
        gid = config.nps.defaultGid;

        user =
          if uid == 0
          then "root"
          else "paperless";
        home =
          if uid == 0
          then "/${user}"
          else "home/${user}";
      in {
        image = "docker.io/garethflowers/ftp-server:0.9.2";
        volumes = [
          "${storage}/consume:${home}"
        ];
        environment = {
          PUBLIC_IP = config.nps.hostIP4Address;
          FTP_USER = user;
          UID = uid;
          GID = gid;
        };
        environmentFile = [cfg.ftp.envFile];
        ports = [
          "21:21"
          "40000-40009:40000-40009"
        ];
      };
    };
  };
}
