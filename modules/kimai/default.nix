{
  config,
  lib,
  ...
}:
let
  name = "kimai";
  dbName = "${name}-db";

  storage = "${config.nps.storageBaseDir}/${name}";

  cfg = config.nps.stacks.${name};
in
{
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email address of the admin user";
    };
    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the admin password";
    };

    db = {
      databaseName = lib.mkOption {
        type = lib.types.str;
        default = "kimai";
        description = "Name of the database to use for Kimai.";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "kimai";
        description = "Username for the Kimai database user.";
      };
      userPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the Kimai database user.";
      };
      rootPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the MySQL root user.";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        # renovate: versioning=regex:^(?<compatibility>.*)-(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$
        image = "docker.io/kimai/kimai2:apache-2.38.0";
        volumes = [
          "${storage}/data:/opt/kimai/var/data"
          "${storage}/plugins:/opt/kimai/var/plugins"
        ];

        extraEnv = {
          ADMINMAIL = cfg.adminEmail;
          ADMINPASS.fromFile = cfg.adminPasswordFile;

          DATABASE_PASSWORD.fromFile = cfg.db.userPasswordFile;
          DATABASE_URL.fromTemplate = "mysql://${cfg.db.username}:\${DATABASE_PASSWORD}@${dbName}/${cfg.db.databaseName}?charset=utf8mb4";
        };

        dependsOnContainer = [ dbName ];
        stack = name;

        port = 8001;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Kimai";
          settings = {
            description = "Time Tracker";
            icon = "kimai";
          };
        };
      };

      ${dbName} = {
        image = "docker.io/mysql:9";
        volumes = [ "${storage}/db:/var/lib/mysql" ];
        extraEnv = {
          MYSQL_DATABASE = cfg.db.databaseName;
          MYSQL_USER = cfg.db.username;
          MYSQL_PASSWORD.fromFile = cfg.db.userPasswordFile;
          MYSQL_ROOT_PASSWORD.fromFile = cfg.db.rootPasswordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "mysqladmin -p\\$MYSQL_ROOT_PASSWORD ping -h localhost";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "20s";
        };

        stack = name;
      };
    };
  };
}
