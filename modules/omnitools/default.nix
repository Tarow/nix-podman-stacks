{
  config,
  lib,
  ...
}: let
  name = "omnitools";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Tool Collection";
  displayName = "OmniTools";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/iib0011/omni-tools:0.5.0";

      port = 80;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "omni-tools";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:omni-tools";
      };
    };
  };
}
