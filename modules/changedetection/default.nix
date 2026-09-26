{
  config,
  lib,
  ...
}: let
  name = "changedetection";
  browserName = "${name}-browser";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  displayName = "Changedetection";
  description = "Website Change Detection";
in {
  imports = import ../mkAliases.nix config lib name [name browserName];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/dgtlmoon/changedetection.io:0.60.7";

        volumeMap.data = "${storage}:/datastore";

        environment = {
          PLAYWRIGHT_DRIVER_URL = "ws://${browserName}:3000";
        };

        extraPodmanArgs = ["--memory=1g"];

        stack = name;
        port = 5000;
        traefik.name = name;
        dashboard = {
          inherit category description;
          name = displayName;
          icon = "di:changedetection";
        };
        homepage.settings.widget.type = "changedetectionio";
      };

      ${browserName} = {
        image = "docker.io/dgtlmoon/sockpuppetbrowser:latest";
        environment = {
          SCREEN_WIDTH = 1920;
          SCREEN_HEIGHT = 1024;
          SCREEN_DEPTH = 16;
          MAX_CONCURRENT_CHROME_PROCESSES = 10;
        };
        addCapabilities = ["SYS_ADMIN"];

        stack = name;
        dashboard = {
          inherit category;
          name = "Sockpuppetbrowser";
          icon = "di:chrome";
          parent = name;
        };
        homepage.category = null;
      };
    };
  };
}
