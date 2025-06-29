{
  config,
  lib,
  ...
}: let
  name = "paperless";
  dbName = "${name}-db";
  brokerName = "${name}-broker";
  ftpName = "${name}-ftp";

  cfg = config.tarow.podman.stacks.${name};
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
in {
  imports = import ../mkAliases.nix lib name [name dbName brokerName ftpName];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
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
      enable = lib.mkEnableOption "FTP server" // {default = true;};
      envFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the env file containing the 'FTP_PASS' variable
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        dependsOnContainer = [dbName brokerName];
        volumes = [
          "${storage}/data:/usr/src/paperless/data"
          "${storage}/media:/usr/src/paperless/media"
          "${storage}/export:/usr/src/paperless/export"
          "${storage}/consume:/usr/src/paperless/consume"
        ];
        environment = {
          PAPERLESS_REDIS = "redis://${brokerName}:6379";
          PAPERLESS_DBHOST = dbName;
          USERMAP_UID = config.tarow.podman.defaultUid;
          USERMAP_GID = config.tarow.podman.defaultGid;
          PAPERLESS_OCR_LANGUAGES = "eng deu";
          PAPERLESS_TIME_ZONE = config.tarow.podman.defaultTz;
          PAPERLESS_OCR_LANGUAGE = "deu";
          PAPERLESS_FILENAME_FORMAT = "{{created_year}}/{{correspondent}}/{{title}}";
          PAPERLESS_URL = config.services.podman.containers.${name}.traefik.serviceDomain;
        };
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
        image = "docker.io/redis:6.0";
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
        uid = config.tarow.podman.defaultUid;
        gid = config.tarow.podman.defaultGid;

        user =
          if uid == 0
          then "root"
          else "paperless";
        home =
          if uid == 0
          then "/${user}"
          else "home/${user}";
      in {
        image = "docker.io/garethflowers/ftp-server";
        volumes = [
          "${storage}/consume:${home}"
        ];
        environment = {
          PUBLIC_IP = config.tarow.podman.hostIP4Address;
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
