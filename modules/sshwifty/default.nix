{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "sshwifty";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  description = "SSH & Telnet Client";
  displayName = "Sshwifty";

  json = pkgs.formats.json {};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr json.type;
      default = {};
      description = ''
        Configuration settings that will be mounted as the `sshwifty.conf.json` file.
        The final configuration file will be templated with `gomplate`, so secrets can be read from files or environment variables for example.

        See <https://github.com/nirui/sshwifty?tab=readme-ov-file#configuration>
      '';
      example = {
        SharedKey = "{{ file.Read `/run/secrets/web_password`}}";
      };
      apply = settings:
        if (settings != null)
        then (json.generate "sshwifty.conf.json" settings)
        else null;
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name}.settings = {
      HostName = cfg.containers.${name}.traefik.serviceHost;
      Servers = [
        {
          ListenInterface = "0.0.0.0";
          ListenPort = 8182;
        }
      ];
    };

    services.podman.containers.${name} = let
      configPath = "/etc/sshwifty.conf.json";
    in {
      image = "docker.io/niruix/sshwifty:0.4.1-beta-release";
      user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
      environment = {
        SSHWIFTY_CONFIG = lib.mkIf (cfg.settings != null) configPath;
      };

      templateMount = lib.optional (cfg.settings != null) {
        templatePath = cfg.settings;
        destPath = configPath;
      };

      port = 8182;
      traefik = {
        name = "sshwifty";
        subDomain = "ssh";
      };
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "sshwifty";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:sshwifty";
      };
    };
  };
}
