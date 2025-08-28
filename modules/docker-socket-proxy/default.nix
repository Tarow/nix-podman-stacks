{
  config,
  lib,
  ...
}: let
  name = "docker-socket-proxy";
  cfg = config.nps.stacks.${name};
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
      image = "ghcr.io/tecnativa/docker-socket-proxy:v0.4.0";

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
        category = "Network & Administration";
        name = "Docker Socket Proxy";
        settings = {
          href = "${cfg.containers.${name}.traefik.serviceUrl}/version";
          description = "Security Proxy for the Docker Socket";
          icon = "haproxy";
        };
      };
    };
  };
}
