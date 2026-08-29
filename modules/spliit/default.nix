{
  config,
  lib,
  ...
}: let
  name = "spliit";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Self-hosted expense sharing";
  displayName = "Spliit";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "spliit";
        description = "Username for the PostgreSQL database.";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "The file containing the PostgreSQL password for the database.";
      };
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/spliit-app/spliit#configuration>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/spliit-app/spliit:1.23.1";

        volumeMap = {
          cache = "${storage}/cache:/usr/app/.next/cache";
        };
        extraEnv =
          {
            BASE_URL = config.services.podman.containers.${name}.traefik.serviceUrl;
            POSTGRES_PRISMA_URL.fromTemplate = "postgresql://${cfg.db.username}:{{ file.Read `${cfg.db.passwordFile}` }}@${dbName}:5432/spliit";
            POSTGRES_URL_NON_POOLING.fromTemplate = "postgresql://${cfg.db.username}:{{ file.Read `${cfg.db.passwordFile}` }}@${dbName}:5432/spliit";
          }
          // cfg.extraEnv;

        wantsContainer = [dbName];
        stack = name;

        port = 3000;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "spliit";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:spliit";
        };
      };

      ${dbName} = {
        image = "docker.io/postgres:18";
        stack = name;
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";
        extraEnv = {
          POSTGRES_DB = "spliit";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };
        glance = {
          parent = name;
          name = "Postgres";
          icon = "di:postgres";
          inherit category;
        };
      };
    };
  };
}
