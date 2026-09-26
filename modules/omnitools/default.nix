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
      image = "docker.io/iib0011/omni-tools:0.6.0";

      port = 80;
      traefik.name = name;
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:omni-tools";
      };
    };
  };
}
