{
  config,
  lib,
  ...
}: let
  name = "nomad";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  displayName = "Nomad";
  description = "Collaborative Travel Planner";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/mauriceboe/nomad:2.6.1";
      volumeMap = {
        data = "${storage}/data:/app/data";
        uploads = "${storage}/uploads:/app/uploads";
      };
      environment = {
        PORT = 3000;
        NODE_ENV = "production";
      };

      port = 3000;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "adguard-home";
          widget.type = "adguard";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:adguard-home";
      };
    };
  };
}
