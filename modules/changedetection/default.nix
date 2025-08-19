{
  config,
  lib,
  ...
}: let
  name = "changedetection";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name "sockpuppetbrowser"];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/dgtlmoon/changedetection.io:0.50.10";
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
