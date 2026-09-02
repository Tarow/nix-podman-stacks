{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "sablier";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  displayName = "Sablier";
  description = "On Demand Service Scaling";

  yaml = pkgs.formats.yaml {};
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Configuration settings for Sablier.

        For details see <https://sablierapp.dev/tutorials/configuration/#configuration-file>.
      '';
      apply = yaml.generate "sablier.yml";
    };
    defaultStrategy = lib.mkOption {
      description = ''
        The default strategy that the sablier middlewares will use.

        For details see
        - <https://sablierapp.dev/concepts/strategies/>
        - <https://plugins.traefik.io/plugins/69104ac3b7d4dd76110a1a09/sablier>
      '';
      type = lib.types.enum [
        "dynamic"
        "blocking"
      ];
      default = "dynamic";
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.traefik.provider = "file";
    nps.stacks.${name}.settings = {
      provider = {
        name = "systemd";
        systemd = {
          unit-patterns = ["podman-*.service"];
        };
      };
      server.port = 10000;
    };

    services.podman.containers = let
      configDst = "/etc/sablier/sablier.yml";
    in {
      ${name} = {
        image = "ghcr.io/sablierapp/sablier:1.18.0";

        volumeMap = {
          config = "${cfg.settings}:${configDst}";
          dbusSocket = "%t/bus:/var/run/dbus/system_bus_socket";
          unitDir = "${config.xdg.configHome}/systemd/user:${config.xdg.configHome}/systemd/user"; # Unit symlinks pointing to nix store
          nixStore = "/nix/store:/nix/store"; # Final unit files to read labels from
        };
        exec = "start --configFile=${configDst}";
        autoUpdate = "local";

        traefik.name = name;

        port = 10000;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            description = description;
            icon = "sh-sablier";
          };
        };
        glance = {
          inherit category;
          description = description;
          name = displayName;
          id = name;
          icon = "sh:sablier";
        };
      };
    };
  };
}
