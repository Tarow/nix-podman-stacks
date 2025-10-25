{
  config,
  lib,
  ...
}: let
  name = "networking-toolbox";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Networking Tools";
  displayName = "Networking Toolbox";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/lissy93/networking-toolbox:1.5.0";
      environment = {
        NODE_ENV = "production";
        PORT = 3000;
        HOST = "0.0.0.0";
      };
      extraConfig.Container = {
        HealthCmd = "wget -qO- http://127.0.0.1:3000/health";
        HealthInterval = "30s";
        HealthTimeout = "10s";
        HealthRetries = 3;
        HealthStartPeriod = "20s";
      };

      port = 3000;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "https://raw.githubusercontent.com/Lissy93/networking-toolbox/main/static/icon.png";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "https://raw.githubusercontent.com/Lissy93/networking-toolbox/main/static/icon.png";
      };
    };
  };
}
