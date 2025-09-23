{
  config,
  lib,
  ...
}: let
  name = "docker-socket-proxy";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  description = "Security Proxy for the Docker Socket";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    address = lib.mkOption {
      type = lib.types.str;
      default = "tcp://${name}:${toString cfg.port}";
      description = "The internal address of the Docker Socket Proxy service.";
      readOnly = true;
      visible = false;
    };
    port = lib.mkOption {
      type = lib.types.port;
      internal = true;
      default = 2375;
      description = "Port on which the Docker Socket Proxy will listen.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/tecnativa/docker-socket-proxy:v0.4.1";

      volumes = [
        "${config.nps.socketLocation}:/var/run/docker.sock:ro"
      ];

      dependsOn = ["podman.socket"];

      environment = {
        CONTAINERS = 1;
        SERVICES = 1;
        TASKS = 1;
        INFO = 1;
        IMAGES = 1;
        NETWORKS = 1;
        CONFIGS = 1;
        POST = 0;
      };

      stack = name;

      port = cfg.port;
      traefik.name = "dsp";
      homepage = {
        inherit category;
        settings = {
          inherit description;
          icon = "haproxy";
        };
      };
      glance = {
        inherit category description;
        id = name;
        icon = "di:haproxy";
      };
    };
  };
}
