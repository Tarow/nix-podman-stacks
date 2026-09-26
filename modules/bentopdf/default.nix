{
  config,
  lib,
  ...
}: let
  name = "bentopdf";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Client-side PDF Toolkit";
  displayName = "BentoPDF";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/alam00000/bentopdf-simple:2.8.8";

      port = 8080;
      traefik.name = name;
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:bentopdf";
      };
    };
  };
}
