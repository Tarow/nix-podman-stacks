{
  config,
  lib,
  ...
}: let
  name = "fredy";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Self-Hosted Real Estate Finder";
  displayName = "Fredy";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      # renovate: datasource=docker depName=ghcr.io/orangecoding/fredy
      image = "ghcr.io/orangecoding/fredy:27.6.0";

      volumeMap = {
        conf = "${storage}/conf:/conf";
        db = "${storage}/db:/db";
      };

      port = 9998;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "https://raw.githubusercontent.com/orangecoding/fredy/refs/heads/master/doc/logo_white.png";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "https://raw.githubusercontent.com/orangecoding/fredy/refs/heads/master/doc/logo_white.png";
      };
    };
  };
}
