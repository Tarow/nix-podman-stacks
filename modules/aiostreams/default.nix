{
  config,
  lib,
  ...
}: let
  name = "aiostreams";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Media & Downloads";
  description = "Stream Source Aggregator";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Can be used to pass secrets such as the `TMDB_ACCESS_TOKEN`.

        See <https://github.com/Viren070/AIOStreams/wiki/Configuration>
      '';
      example = {
        TMDB_ACCESS_TOKEN = {
          fromFile = "/run/secrets/tmdb_access_token";
        };
        FOO = "bar";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/viren070/aiostreams:v2.13.3";
      extraConfig.Container = {
        HealthCmd = "wget -qO- http://localhost:3000/api/v1/status";
        HealthInterval = "1m";
        HealthTimeout = "10s";
        HealthRetries = 5;
        HealthStartPeriod = "10s";
      };
      volumes = ["${storage}/data:/app/data"];
      environment = {
        ADDON_NAME = "AIOStreams";
        ADDON_ID = "aiostreams.viren070.com";
        PORT = 3000;
        BASE_URL = config.services.podman.containers.${name}.traefik.serviceUrl;
      };
      extraEnv = cfg.extraEnv;

      port = 3000;
      traefik.name = name;

      homepage = {
        inherit category;
        settings = {
          inherit description;
          icon = "stremio";
        };
      };
      glance = {
        inherit category description;
        id = name;
        icon = "di:stremio";
      };
    };
  };
}
