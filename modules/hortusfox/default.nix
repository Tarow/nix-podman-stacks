{
  config,
  lib,
  ...
}: let
  name = "hortusfox";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  displayName = "HortusFox";
  description = "Plant Management System";
in {
  imports = import ../mkAliases.nix config lib name [name dbName];
  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminEmail = lib.mkOption {
      type = lib.types.str;
      default = "admin@example.com";
      description = ''
        E-Mail of the admin user
      '';
    };
    adminPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the file containing the admin password.

        When using proxy auth, this can also be unset
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.

        See <https://github.com/danielbrendel/hortusfox-web?tab=readme-ov-file#installation>
      '';
      example = lib.literalExpression ''
        {
          PROXY_ENABLE = true;
          PROXY_HEADER_EMAIL = "Remote-Email";
          PROXY_HEADER_USERNAME = "Remote-User";
          PROXY_AUTO_SIGNUP = true;
          PROXY_WHITELIST = config.nps.stacks.traefik.ip4;
          PROXY_HIDE_LOGOUT = true;
        }'';
    };
    db = {
      userPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the romm database user";
      };
      rootPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the MariaDB root user";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/danielbrendel/hortusfox-web:v5.4";
        volumes = [
          "${storage}/img:/var/www/html/public/img"
          "${storage}/logs:/var/www/html/app/logs"
          "${storage}/backup:/var/www/html/public/backup"
          "${storage}/themes:/var/www/html/public/themes"
          "${storage}/migrations:/var/www/html/app/migrations"
        ];

        extraEnv = let
          db = cfg.containers.${dbName}.environment;
        in
          {
            APP_ADMIN_EMAIL = cfg.adminEmail;
            APP_ADMIN_PASSWORD = lib.mkIf (cfg.adminPasswordFile != null) {fromFile = cfg.adminPasswordFile;};
            APP_TIMEZONE = config.nps.defaultTz;
            DB_HOST = dbName;
            DB_PORT = 3306;
            DB_DATABASE = db.MARIADB_DATABASE;
            DB_USERNAME = db.MARIADB_USER;
            DB_PASSWORD.fromFile = cfg.db.userPasswordFile;
            DB_CHARSET = "utf8mb4";
          }
          // cfg.extraEnv;

        dependsOnContainer = [dbName];
        stack = name;
        port = 80;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "hortusfox";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "sh:hortusfox";
        };
      };

      ${dbName} = {
        image = "docker.io/mariadb:12";
        volumes = ["${storage}/db:/var/lib/mysql"];
        extraEnv = {
          MARIADB_DATABASE = "hortusfox";
          MARIADB_USER = "hortusfox";
          MARIADB_ROOT_PASSWORD.fromFile = cfg.db.rootPasswordFile;
          MARIADB_PASSWORD.fromFile = cfg.db.userPasswordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "healthcheck.sh --connect --innodb_initialized";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "20s";
        };

        stack = name;
        glance = {
          parent = name;
          icon = "si:mariadb";
          inherit category;
        };
      };
    };
  };
}
