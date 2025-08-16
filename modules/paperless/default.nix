{
  config,
  lib,
  options,
  ...
}:
let
  name = "paperless";
  dbName = "${name}-db";
  brokerName = "${name}-broker";
  ftpName = "${name}-ftp";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
in
{
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
    brokerName
    ftpName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the Paperless secret key
              
        See <https://docs.paperless-ngx.com/configuration/#PAPERLESS_SECRET_KEY>
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = { };
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://docs.paperless-ngx.com/configuration>
      '';
    };
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "paperless";
        description = "Database user name for Paperless";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the database password for Paperless";
      };
    };
    ftp = {
      enable = lib.mkEnableOption "FTP server" // {
        default = true;
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the FTP password";
      };
    };
    authelia = {
      registerClient = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to register a Paperless OIDC client in Authelia.
          If enabled you need to provide a hashed secret in the `client_secret` option.

          To enable OIDC Login for Paperless, you will have to provide the environment variable `PAPERLESS_SOCIALACCOUNT_PROVIDERS`,
          e.g. in the `extraEnv` option.

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
        image = "ghcr.io/paperless-ngx/paperless-ngx:2.17.1";
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
        environment = {
          PAPERLESS_REDIS = "redis://${brokerName}:6379";
          PAPERLESS_DBHOST = dbName;
          USERMAP_UID = config.nps.defaultUid;
          USERMAP_GID = config.nps.defaultGid;
          PAPERLESS_TIME_ZONE = config.nps.defaultTz;
          PAPERLESS_FILENAME_FORMAT = "{{created_year}}/{{correspondent}}/{{title}}";
          PAPERLESS_URL = config.services.podman.containers.${name}.traefik.serviceDomain;
        }
        // lib.optionalAttrs cfg.authelia.registerClient {
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        };

        extraEnv = {
          PAPERLESS_DBUSER = cfg.db.username;
          PAPERLESS_DBPASS.fromFile = cfg.db.passwordFile;
          PAPERLESS_SECRET_KEY.fromFile = cfg.secretKeyFile;
        }
        // cfg.extraEnv;

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
        volumes = [ "${storage}/db:/var/lib/postgresql/data" ];
        extraEnv = {
          POSTGRES_DB = "paperless";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        stack = name;
      };

      ${ftpName} =
        let
          uid = config.nps.defaultUid;
          gid = config.nps.defaultGid;

          user = if uid == 0 then "root" else "paperless";
          home = if uid == 0 then "/${user}" else "home/${user}";
        in
        {
          image = "docker.io/garethflowers/ftp-server:0.9.2";
          volumes = [
            "${storage}/consume:${home}"
          ];
          extraEnv = {
            PUBLIC_IP = config.nps.hostIP4Address;
            FTP_USER = user;
            FTP_PASS.fromFile = cfg.ftp.passwordFile;
            UID = uid;
            GID = gid;
          };

          ports = [
            "21:21"
            "40000-40009:40000-40009"
          ];
        };
    };
  };
}
