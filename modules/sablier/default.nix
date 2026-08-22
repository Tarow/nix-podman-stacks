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

  src = builtins.fetchGit {
    url = "https://github.com/Tarow/sablier";
    ref = "main";
    rev = "262cd927f4aaeaca22a8b0762d2a061ae0cb9145";
  };
  tag = "localhost/tarow/sablier:latest";
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
    nps.stacks.${name}.settings = {
      provider = {
        name = "systemd";
        systemd = {
          unit-patterns = ["podman-*.service"];
        };
      };
      server.port = 10000;
    };

    services.podman = let
      configDst = "/etc/sablier/sablier.yml";
    in {
      builds.${name} = {
        file = toString ./Dockerfile;
        tags = [tag];
        workingDirectory = toString src;
      };
      containers.${name} = {
        image = "${name}.build";

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
            icon = "sablier";
          };
        };
        glance = {
          inherit category;
          description = description;
          name = displayName;
          id = name;
          icon = "di:sablier";
        };
      };
    };
  };
}
