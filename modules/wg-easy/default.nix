{
  config,
  lib,
  ...
}: let
  name = "wg-easy";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  description = "VPN Server";
  displayName = "wg-easy";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    host = lib.mkOption {
      type = lib.types.str;
      description = ''
        The external domain or IP address of the Wireguard server.
        Will be used as the 'endpoint' when generating client configurations.

        Only has an effect during initial setup.
        See <https://wg-easy.github.io/wg-easy/v15.1/advanced/config/unattended-setup/>
      '';
      default =
        if config.nps.stacks.traefik.enable
        then "vpn.${config.nps.stacks.traefik.domain}"
        else config.nps.hostIP4Address;
      defaultText = lib.literalExpression ''"vpn.''${config.nps.stacks.traefik.domain}"'';
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = ''
        The port on which the Wireguard server will listen.
        Will be passed as INIT_PORT during initial setup.
        Only has an effect during initial setup.
        See <https://wg-easy.github.io/wg-easy/v15.1/advanced/config/unattended-setup/>
      '';
      default = 51820;
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://wg-easy.github.io/wg-easy/latest/advanced/config/unattended-setup/>
      '';
      example = {
        INIT_PASSWORD = {
          fromFile = "/run/secrets/wg_easy_admin_password";
        };
        INIT_DNS = "1.1.1.1";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/wg-easy/wg-easy:15.1.0";
      volumes = [
        "${storage}/config:/etc/wireguard"
      ];

      ports = ["${toString cfg.port}:${toString cfg.port}/udp"];
      addCapabilities = [
        "NET_ADMIN"
        "NET_RAW"
        "SYS_MODULE"
      ];
      extraPodmanArgs = [
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--sysctl=net.ipv4.ip_forward=1"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
        "--sysctl=net.ipv6.conf.all.forwarding=1"
        "--sysctl=net.ipv6.conf.default.forwarding=1"
      ];

      environment = {
        INIT_ENABLED = true;
        INIT_HOST = cfg.host;
        INIT_USERNAME = "admin";
        INIT_PORT = cfg.port;
        INIT_IPV4_CIDR = "172.20.0.0/24";
        INIT_IPV6_CIDR = "2001:0DB8::/32";
      };

      extraEnv = cfg.extraEnv;

      port = 51821;
      traefik = {
        name = name;
        subDomain = "wg";
      };
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "wireguard";
          widget = {
            type = "wgeasy";
            version = 2;
          };
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:wireguard";
      };
    };
  };
}
