{
  config,
  lib,
  ...
}: let
  name = "aiostreams";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Media & Downloads";
  displayName = "AIOStreams";
  description = "Stream Source Aggregator";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key. Must be a 64-character hex string.
        Can be generated using `openssl rand -hex 32`

        See <https://github.com/outline/outline/blob/main/.env.sample>
      '';
    };
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
      image = "ghcr.io/viren070/aiostreams:v2.25.0";
      extraConfig.Container = {
        HealthCmd = "wget -qO- http://localhost:3000/api/v1/status";
        HealthInterval = "1m";
        HealthTimeout = "10s";
        HealthRetries = 5;
        HealthStartPeriod = "10s";
        HealthOnFailure = "kill";
      };
      volumeMap.data = "${storage}/data:/app/data";
      environment = {
        ADDON_NAME = "AIOStreams";
        ADDON_ID = "aiostreams.viren070.com";
        PORT = 3000;
        BASE_URL = config.services.podman.containers.${name}.traefik.serviceUrl;
      };
      extraEnv =
        {
          SECRET_KEY.fromFile = cfg.secretKeyFile;
        }
        // cfg.extraEnv;

      port = 3000;
      traefik.name = name;

      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "stremio";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:stremio";
      };
    };
  };
}
