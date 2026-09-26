{
  config,
  lib,
  ...
}: let
  name = "mazanoke";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Image Optimizer";
  displayName = "Mazanoke";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/civilblur/mazanoke:v1.1.7";

      port = 80;
      traefik.name = name;
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:mazanoke";
      };
      glance.icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/mazanoke.webp";
    };
  };
}
