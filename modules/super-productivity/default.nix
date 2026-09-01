{
  config,
  lib,
  ...
}: let
  name = "super-productivity";
  syncName = "supersync";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Todo List & Time Tracking";
  displayName = "Super Productivity";

  supersyncHost = config.nps.containers.${syncName}.traefik.serviceHost;
  supersyncUrl = config.nps.containers.${syncName}.traefik.serviceUrl;
  appUrl = config.nps.containers.${name}.traefik.serviceUrl;
in {
  imports = import ../mkAliases.nix config lib name [
    name
    syncName
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

    enableSync = lib.mkEnableOption "SuperSync server with PostgreSQL";
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the SuperSync JWT secret. Generate with `openssl rand -hex 32`. Only required when enableSync is true.";
    };
    db.passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the PostgreSQL password for the SuperSync database. Only required when enableSync is true.";
    };
    smtp = {
      host = lib.mkOption {
        type = lib.types.str;
        description = "SMTP server hostname for email delivery.";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 587;
        description = "SMTP server port.";
      };
      secure = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to use TLS for SMTP connections.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        description = "SMTP username.";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to file containing the SMTP password.";
      };
      from = lib.mkOption {
        type = lib.types.str;
        description = "Sender email address (e.g. 'SuperSync <noreply@example.com>').";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "docker.io/johannesjo/super-productivity:v18.21.2";

        stack = name;
        port = 80;
        traefik.name = name;

        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "super-productivity";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:super-productivity.png";
        };
      };

      ${syncName} = lib.mkIf cfg.enableSync {
        image = "ghcr.io/warreth/super-sync-server:v18.21.2";
        stack = name;

        volumeMap.data = "${storage}/supersync:/data";

        environment = {
          NODE_ENV = "production";
          PORT = 1900;
          DATA_DIR = "/data";
          PUBLIC_URL = supersyncUrl;
          CORS_ORIGINS = lib.concatStringsSep "," [appUrl supersyncUrl];
          WEBAUTHN_RP_ID = supersyncHost;
          WEBAUTHN_RP_NAME = "Super Productivity Sync";
          WEBAUTHN_ORIGIN = supersyncUrl;
          RUN_MIGRATIONS_ON_STARTUP = true;
        };

        extraEnv = {
          JWT_SECRET.fromFile = cfg.jwtSecretFile;
          DATABASE_URL.fromTemplate = "postgresql://supersync:{{ file.Read `${cfg.db.passwordFile}` }}@${dbName}:5432/supersync";
          SMTP_HOST = cfg.smtp.host;
          SMTP_PORT = cfg.smtp.port;
          SMTP_SECURE = cfg.smtp.secure;
          SMTP_USER = cfg.smtp.user;
          SMTP_PASS.fromFile = cfg.smtp.passwordFile;
          SMTP_FROM = cfg.smtp.from;
        };

        port = 1900;
        wantsContainer = [dbName];
        traefik.name = syncName;

        extraConfig.Container = {
          HealthCmd = "wget --quiet --tries=1 --spider http://127.0.0.1:1900/health";
          HealthInterval = "30s";
          HealthTimeout = "5s";
          HealthRetries = 3;
          HealthStartPeriod = "20s";
        };

        glance = {
          inherit category description;
          parent = name;
          name = "SuperSync";
          icon = "di:super-productivity.png";
        };
      };

      ${dbName} = lib.mkIf cfg.enableSync {
        image = "docker.io/postgres:18";
        stack = name;
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";
        extraEnv = {
          POSTGRES_DB = "supersync";
          POSTGRES_USER = "supersync";
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

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
