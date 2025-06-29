{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "immich";

  dbName = "${name}-db";
  redisName = "${name}-redis";
  mlName = "${name}-machine-learning";

  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  mediaStorage = "${config.tarow.podman.mediaStorageBaseDir}";
  cfg = config.tarow.podman.stacks.${name};

  env =
    {
      DB_HOSTNAME = dbName;
      DB_USERNAME = "postgres";
      DB_DATABASE_NAME = "immich";
      REDIS_HOSTNAME = redisName;
      NODE_ENV = "production";
      UPLOAD_LOCATION = "/usr/src/app/upload";
    }
    // lib.optionalAttrs (cfg.settings != null) {
      IMMICH_CONFIG_FILE = "/usr/src/app/config/config.json";
    };

  json = pkgs.formats.json {};
in {
  imports = import ../mkAliases.nix lib name [name redisName dbName mlName];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr json.type;
      apply = settings:
        if (settings != null)
        then (json.generate "config.json" settings)
        else null;
    };
    envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the env file containing the 'DB_PASSWORD' variable
      '';
    };
    db.envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the env file containing the 'POSTGRES_PASSWORD' variable
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${name}.settings = import ./config.nix;

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/immich-app/immich-server:release";
        volumes =
          [
            "${mediaStorage}/pictures/immich:${env.UPLOAD_LOCATION}"
          ]
          ++ lib.optional (cfg.settings != null) "${cfg.settings}:${env.IMMICH_CONFIG_FILE}";

        environment = env;
        environmentFile = [cfg.envFile];

        devices = ["/dev/dri:/dev/dri"];

        dependsOnContainer = [redisName dbName];
        port = 2283;

        stack = name;
        traefik.name = name;
        homepage = {
          category = "Media & Downloads";
          name = "Immich";
          settings = {
            description = "Photo & Video Management";
            icon = "immich";
            widget.type = "immich";
          };
        };
      };

      ${redisName} = {
        image = "docker.io/redis:6.2";
        stack = name;
      };

      ${dbName} = {
        image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0";
        volumes = ["${storage}/pgdata:/var/lib/postgresql/data"];
        environmentFile = [cfg.db.envFile];
        environment = {
          POSTGRES_USER = env.DB_USERNAME;
          POSTGRES_DB = env.DB_DATABASE_NAME;
        };

        stack = name;
      };

      ${mlName} = {
        image = "ghcr.io/immich-app/immich-machine-learning:release";
        volumes = ["${storage}/model-cache:/cache"];

        stack = name;
      };
    };
  };
}
