{
  config,
  lib,
  ...
}: let
  name = "baikal";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "DAV Server";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/ckulka/baikal:0.10.1-nginx";
      volumes = [
        "${storage}/config:/var/www/baikal/config"
        "${storage}/data:/var/www/baikal/Specific"
      ];

      port = 80;
      traefik.name = name;
      homepage = {
        inherit category;
        settings = {
          inherit description;
          icon = "baikal";
        };
      };
      glance = {
        inherit category description;
        id = name;
        icon = "di:baikal";
      };
    };
  };
}
