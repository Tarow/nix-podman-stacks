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
      image = "ghcr.io/alam00000/bentopdf:v1.9.0";

      port = 8080;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "bentopdf";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:bentopdf";
      };
    };
  };
}
