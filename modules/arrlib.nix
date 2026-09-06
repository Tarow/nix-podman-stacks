{
  config,
  lib,
  pkgs,
  stackName,
  storage,
  mediaStorage,
  category,
}: let
  cfg = config.nps.stacks.${stackName};
  mkCfg = name:
    if name == stackName
    then cfg
    else cfg.${name};
in rec {
  mkArrOptions = name: {
    enable =
      lib.mkEnableOption name
      // {
        default = true;
      };
    extraEnv = lib.mkOption {
      type = (import ./types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).
      '';
    };
    db = {
      type = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
        default = "sqlite";
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the `passwordFile` option must be set.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = ''
          The PostgreSQL user to use for the database.
          Only used if db.type is set to "postgres".
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the PostgreSQL password for the database.
          Only used if db.type is set to "postgres".
        '';
      };
    };
  };

  mkArrBase = name: let
    arrCfg = mkCfg name;
    upperName = lib.toUpper name;
  in {
    volumeMap = {
      config = "${storage}/${name}:/config";
      media = "${mediaStorage}:/media";
    };

    extraEnv =
      {
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
        "${upperName}__AUTH__METHOD" = "Forms";
        "${upperName}__AUTH__REQUIRED" = "DisabledForLocalAddresses";
      }
      // lib.optionalAttrs (arrCfg.db.type == "postgres") {
        "${upperName}__POSTGRES__HOST" = "${name}-db";
        "${upperName}__POSTGRES__USER" = arrCfg.db.username;
        "${upperName}__POSTGRES__PASSWORD".fromFile = arrCfg.db.passwordFile;
        "${upperName}__POSTGRES__MAINDB" = name;
        "${upperName}__POSTGRES__LOGDB" = "${name}_log";
      }
      // arrCfg.extraEnv;

    wantsContainer = lib.optional (arrCfg.db.type == "postgres") "${name}-db";

    stack = stackName;
    traefik.name = name;
  };

  mkArrPostgres = name: let
    arrCfg = mkCfg name;
  in
    lib.mkIf (arrCfg.db.type == "postgres") {
      image = "docker.io/postgres:18";
      volumeMap = let
        init = pkgs.writeText "init.sql" ''
          CREATE DATABASE ${name}_log;
        '';
      in {
        # Needs extra folder, otherwise its mounted into *arr, which will chown all folders -> db fails to start
        data = "${storage}/${name}_postgres:/var/lib/postgresql";
        initSql = "${init}:/docker-entrypoint-initdb.d/init.sql";
      };

      extraEnv = {
        POSTGRES_USER = arrCfg.db.username;
        POSTGRES_DB = name;
        POSTGRES_PASSWORD.fromFile = arrCfg.db.passwordFile;
      };

      extraConfig.Container = {
        Notify = "healthy";
        HealthCmd = "pg_isready -h 127.0.0.1 -d ${name}_log -U ${arrCfg.db.username}";
        HealthInterval = "10s";
        HealthTimeout = "10s";
        HealthRetries = 5;
        HealthStartPeriod = "10s";
        HealthOnFailure = "kill";
      };

      stack = stackName;
      glance = {
        inherit category;
        name = "Postgres";
        parent = name;
        icon = "di:postgres";
      };
    };

  arrDbs = names:
    lib.genAttrs' names (name: lib.nameValuePair "${name}-db" (mkArrPostgres name));
}
