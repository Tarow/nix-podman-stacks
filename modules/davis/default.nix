{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "davis";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  displayName = "Davis";
  description = "DAV Server";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminUsername = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = ''
        Admin username to access the dashboard.
      '';
    };
    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the admin password.
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/tchapi/davis/blob/main/docker/.env>
      '';
      example = {
        MAIL_PASSWORD = {
          fromFile = "/run/secrets/secret_name";
        };
        MAIL_HOST = "smtp.myprovider.com";
      };
    };
    enableLdapAuth = lib.mkOption {
      type = lib.types.bool;
      default = config.nps.stacks.lldap.enable;
      defaultText = lib.literalExpression ''config.nps.stacks.lldap.enable'';
      description = ''
        Whether to enable login via LLDAP as an auth provider
      '';
    };

    db = {
      type = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "mysql"
        ];
        default = "mysql";
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "mysql".
          If set to "mysql", the `userPasswordFile` and `rootPasswordFile` options must be set.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "davis";
        description = "Username for the davis database user.";
      };
      userPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the davis database user.";
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
        image = "ghcr.io/tchapi/davis-standalone:5.3.0";
        volumes = lib.optional (cfg.db.type == "sqlite") "${storage}/sqlite:/data";

        extraEnv =
          {
            APP_ENV = "prod";
            CALDAV_ENABLED = true;
            CARDDAV_ENABLED = true;
            WEBDAV_ENABLED = false;
            PUBLIC_CALENDARS_ENABLED = true;
            APP_TIMEZONE = config.nps.defaultTz;
            ADMIN_LOGIN = cfg.adminUsername;
            ADMIN_PASSWORD.fromFile = cfg.adminPasswordFile;
            AUTH_METHOD = "Basic";
            AUTH_REALM = "SabreDAV";
            DATABASE_DRIVER = "sqlite";
            DATABASE_URL = "sqlite:////data/davis-database.db";
          }
          // lib.optionalAttrs cfg.enableLdapAuth (let
            lldap = config.nps.stacks.lldap;
          in {
            AUTH_METHOD = "LDAP";
            LDAP_AUTH_URL = lldap.address;
            LDAP_DN_PATTERN = "uid=%%u,OU=people," + lldap.baseDn;
            LDAP_MAIL_ATTRIBUTE = "mail";
            LDAP_AUTH_USER_AUTOCREATE = true;
            LDAP_CERTIFICATE_CHECKING_STRATEGY = "try";
          })
          // lib.optionalAttrs (cfg.db.type == "mysql") {
            DATABASE_DRIVER = "mysql";
            DATABASE_URL.fromTemplate = "mysql://${cfg.db.username}:{{ file.Read `${cfg.db.userPasswordFile}` }}@${dbName}/davis?serverVersion=mariadb-12.0.2&charset=utf8mb4";
          };

        extraConfig.Service.ExecStartPost = [
          (lib.getExe (
            pkgs.writeShellScriptBin "${name}-migrations" ''
              ${lib.getExe config.nps.package} exec ${name} sh -c "APP_ENV=prod bin/console doctrine:migrations:migrate --no-interaction"
            ''
          ))
        ];

        dependsOnContainer = lib.optional (cfg.db.type == "mysql") dbName;
        stack = name;
        port = 9000;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "davis";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/davis.webp";
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "mysql") {
        image = "docker.io/mariadb:12.0.2";
        volumes = ["${storage}/db:/var/lib/mysql"];
        extraEnv = {
          MYSQL_DATABASE = "davis";
          MYSQL_USER = cfg.db.username;
          MYSQL_PASSWORD.fromFile = cfg.db.userPasswordFile;
          MYSQL_ROOT_PASSWORD.fromFile = cfg.db.rootPasswordFile;
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
          inherit category;
          parent = name;
          name = "MariaDB";
          icon = "di:mariadb";
        };
      };
    };
  };
}
