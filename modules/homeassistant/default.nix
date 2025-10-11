{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "homeassistant";
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};

  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Home Automation";
  displayName = "Home Assistant";

  traefikSubnet = config.nps.stacks.traefik.network.subnet;
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr yaml.type;
      apply = settings:
        if settings != null
        then yaml.generate "configuration.yaml" settings
        else null;
      description = ''
        Settings that will be written to the 'configuration.yaml' file.
        If you want to configure settings through the UI, set this option to null.
        In that case, no managed `configuration.yaml` will be provided.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.homeassistant.settings = {
      default_config = {};

      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [traefikSubnet "127.0.0.1" "::1"];
      };
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/home-assistant/home-assistant:2025.10.2";
      volumes =
        [
          "${storage}/config:/config"
          # User should be in 'dialout' group for HA to access bluetooth module
          "/run/dbus:/run/dbus:ro"
        ]
        ++ lib.optional (cfg.settings != null) "${cfg.settings}:/config/configuration.yaml";
      extraConfig.Container.GroupAdd = "keep-groups";

      port = 8123;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "home-assistant";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:home-assistant";
      };
    };
  };
}
