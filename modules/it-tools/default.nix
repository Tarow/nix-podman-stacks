{
  config,
  lib,
  ...
}: let
  name = "it-tools";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Developer Tools";
  displayName = "IT-Tools";
in {
  imports = import ../mkAliases.nix config lib name [name] ++ [(lib.mkRenamedOptionModule ["nps" "stacks" "ittools"] ["nps" "stacks" "it-tools"])];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      # renovate: versioning=regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(?<build>.+)$
      image = "ghcr.io/corentinth/it-tools:2024.10.22-7ca5933";

      port = 80;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "it-tools";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:it-tools";
      };
    };
  };
}
