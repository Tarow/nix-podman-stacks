{
  config,
  lib,
  ...
}: let
  name = "aiostreams";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the environment file for AIOStreams.
        Can be used to pass secrets.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/viren070/aiostreams:v2.9.0";
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
        BASE_URL = config.services.podman.containers.${name}.traefik.serviceDomain;
      };
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

      port = 3000;
      traefik.name = name;
      homepage = {
        category = "Media & Downloads";
        name = "AIOStreams";
        settings = {
          description = "Stream Source Aggregator";
          icon = "stremio";
        };
      };
    };
  };
}
