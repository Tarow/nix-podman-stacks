{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "blocky";
  cfg = config.tarow.podman.stacks.${name};

  yaml = pkgs.formats.yaml {};

  domain = config.tarow.podman.stacks.traefik.domain;
  ip = config.tarow.podman.hostIP4Address;
in {
  imports = import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      apply = yaml.generate "config.yml";
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.${name}.settings = lib.mkMerge [
      (import ./settings.nix)
      {
        customDNS.mapping.${domain} = ip;
      }
    ];

    services.podman.containers.${name} = {
      image = "ghcr.io/0xerr0r/blocky:latest";
      volumes = [
        "${cfg.settings}:/app/config.yml"
      ];
      ports = [
        "${ip}:53:53/udp"
      ];
      port = 4000;
      traefik.name = name;
      homepage = {
        category = "Network & Administration";
        name = "Blocky";
        settings = {
          description = "Adblocker";
          icon = "blocky";
        };
      };
    };
  };
}
