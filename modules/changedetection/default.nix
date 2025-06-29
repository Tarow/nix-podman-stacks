{
  config,
  lib,
  ...
}: let
  name = "changedetection";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix lib name [name "sockpuppetbrowser"];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/dgtlmoon/changedetection.io";
        volumes = [
          "${storage}:/datastore"
        ];
        environment = {
          PLAYWRIGHT_DRIVER_URL = "ws://sockpuppetbrowser:3000";
        };

        extraPodmanArgs = ["--memory=1g"];

        stack = name;
        port = 5000;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Changedetection";
          settings = {
            description = "Website Change Detection";
            icon = "changedetection";
            widget.type = "changedetectionio";
          };
        };
      };

      sockpuppetbrowser = {
        image = "docker.io/dgtlmoon/sockpuppetbrowser:latest";
        environment = {
          SCREEN_WIDTH = 1920;
          SCREEN_HEIGHT = 1024;
          SCREEN_DEPTH = 16;
          MAX_CONCURRENT_CHROME_PROCESSES = 10;
        };
        addCapabilities = ["SYS_ADMIN"];

        stack = name;
      };
    };
  };
}
