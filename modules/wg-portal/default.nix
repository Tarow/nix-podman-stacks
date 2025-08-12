{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "wg-portal";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
  yaml = pkgs.formats.yaml {};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Settings for the wg-portal container.
        Will be converted to YAML and passed to the container.
        See <https://wgportal.org/latest/documentation/configuration/overview/>
      '';
      apply = yaml.generate "config.yaml";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = ''
        The default port for the first Wireguard interface that will be set up in the UI.
        Will be exposed and passed as the 'start_listen_port' setting in the configuration.
      '';
      default = 51820;
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = ''
        Path to the environment file.
        Can be used to pass env variables such as secrets, that are used in the settings.
      '';
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name}.settings = {
      web.external_url = cfg.containers.${name}.traefik.serviceDomain;
      advanced.start_listen_port = cfg.port;
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/h44z/wg-portal:v2.0.4";
      volumes = [
        "${storage}/data:/app/data"
        "${cfg.settings}:/app/config/config.yaml"
      ];
      ports = ["${toString cfg.port}:${toString cfg.port}/udp"];
      addCapabilities = ["NET_ADMIN" "NET_RAW" "SYS_MODULE"];
      extraPodmanArgs = [
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--sysctl=net.ipv4.ip_forward=1"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
        "--sysctl=net.ipv6.conf.all.forwarding=1"
        "--sysctl=net.ipv6.conf.default.forwarding=1"
      ];
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

      port = 8888;
      traefik = {
        name = name;
        subDomain = "wg";
      };
      homepage = {
        category = "Network & Administration";
        name = "Wireguard Portal";
        settings = {
          description = "Wireguard Management UI";
          icon = "wireguard";
        };
      };
    };
  };
}
