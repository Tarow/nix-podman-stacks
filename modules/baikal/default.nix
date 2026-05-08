{
  config,
  lib,
  ...
}: let
  name = "baikal";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  displayName = "Baikal";
  description = "DAV Server";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/ckulka/baikal:0.10.1-nginx";
      volumeMap = {
        config = "${storage}/config:/var/www/baikal/config";
        specific = "${storage}/data:/var/www/baikal/Specific";
      };

      port = 80;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "baikal";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:baikal";
      };
    };
  };
}
