{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "searxng";
  valkeyName = "${name}-valkey";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Metasearch Engine";
  displayName = "SearXNG";

  yaml = pkgs.formats.yaml {};
in {
  imports = import ../mkAliases.nix config lib name [name valkeyName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key.
        Can be generated using `openssl rand -hex 32`.

        See <https://docs.searxng.org/admin/settings/settings_server.html#server>
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://docs.searxng.org/admin/installation-docker.html#environment-variables>
      '';
      example = {
        SEARXNG_DEBUG = true;
      };
    };
    settings = lib.mkOption {
      type = yaml.type;

      default = {};
      description = ''
        Configuration settings for SearXNG.
        Will be provided as the `settings.yml` file.

        See <https://docs.searxng.org/admin/settings/index.html>
      '';
      apply = yaml.generate "settings.yml";
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name}.settings = {
      use_default_settings = true;
      server.base_url = config.nps.containers.${name}.traefik.serviceUrl;
      valkey.url = "valkey://${valkeyName}:6379/0";
    };

    services.podman.containers = {
      ${name} = let
        containerConfigPath = "/config/settings.yml";
      in {
        image = "ghcr.io/searxng/searxng:2026.1.27-966988e36";

        volumeMap = {
          config = "${storage}/config:/etc/searxng";
          data = "${storage}/data:/var/cache/searxng";
          settings = "${cfg.settings}:${containerConfigPath}";
        };
        extraEnv =
          {
            SEARXNG_SECRET.fromFile = cfg.secretKeyFile;
            SEARXNG_SETTINGS_PATH = containerConfigPath;
          }
          // cfg.extraEnv;

        port = 8080;
        traefik.name = name;

        stack = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "searxng";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:searxng";
        };
      };

      ${valkeyName} = {
        image = "docker.io/valkey/valkey:9-alpine";
        volumeMap.data = "${storage}/valkey/data:/data";
        exec = "valkey-server --save 30 1 --loglevel warning";
        stack = name;
        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "valkey-cli ping";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
          HealthOnFailure = "kill";
        };

        glance = {
          parent = name;
          name = "Valkey";
          icon = "di:valkey";
          inherit category;
        };
      };
    };
  };
}
