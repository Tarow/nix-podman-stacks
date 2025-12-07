{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "tsbridge";
  cfg = config.nps.stacks.${name};
  reverseProxyCfg = config.nps.reverseProxy;

  category = "Network & Administration";
  description = "Tailscale Proxy";
  displayName = "tsbridge";

  storage = "${config.nps.storageBaseDir}/${name}";
in {
  imports =
    [
      ./extension.nix
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
    ]
    ++ import ../mkAliases.nix config lib name name;

  options.nps.stacks.${name} = {
    enable =
      lib.options.mkEnableOption name
      // {
        description = ''
          Whether to enable tsbridge.

          tsbridge is a Tailscale reverse proxy that discovers Docker containers
          via labels and automatically exposes them on your Tailnet.
        '';
      };

    oauth = {
      clientId = lib.options.mkOption {
        type = lib.types.str;
        default = null;
        description = ''
          The Tailscale OAuth client ID.
          Required if using OAuth authentication.
        '';
      };
      clientSecretFile = lib.options.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to file containing the Tailscale OAuth client secret.
          Required if using OAuth authentication.
        '';
      };
    };

    defaultTags = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Default Tailscale tags to apply to all exposed services.
        Format: tag:service
      '';
      example = ["tag:prod" "tag:http"];
    };

    tailnetDomain = lib.options.mkOption {
      type = lib.types.str;
      description = ''
        Your Tailscale tailnet domain name.
        This is used to construct the full service URLs.
        Format: tailnet-name.ts.net
      '';
      example = "my-tailnet.ts.net";
    };

    metricsAddr = lib.options.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Address to expose Prometheus metrics on.
        Example: :9090
      '';
    };

    writeTimeout = lib.options.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Global default timeout for writing responses.
        Format: duration string (e.g., "30s", "1m")
        Set to "0s" for no timeout.
      '';
      example = "30s";
    };

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.reverseProxy = {
      domain = cfg.tailnetDomain;
      ip4 = "10.81.0.2";
      network = {
        name = "tsbridge-proxy";
        subnet = "10.81.0.0/24";
        gateway = "10.81.0.1";
        ipRange = "10.81.0.10-10.81.0.255";
      };
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/jtdowney/tsbridge:v0.13.0";

      exec =
        "--provider docker"
        + (lib.optionalString cfg.useSocketProxy " --docker-socket ${config.nps.stacks.docker-socket-proxy.address}");

      extraEnv =
        {
          TSBRIDGE_OAUTH_CLIENT_ID = cfg.oauth.clientId;
          TSBRIDGE_OAUTH_CLIENT_SECRET.fromFile = cfg.oauth.clientSecretFile;
        }
        // cfg.extraEnv;

      volumes = [
        "${storage}/state:/state"
      ];

      labels =
        {
          "tsbridge.tailscale.oauth_client_id_env" = "TSBRIDGE_OAUTH_CLIENT_ID";
          "tsbridge.tailscale.oauth_client_secret_env" = "TSBRIDGE_OAUTH_CLIENT_SECRET";
          "tsbridge.tailscale.state_dir" = "/state";
        }
        // (lib.optionalAttrs (cfg.defaultTags != []) {
          "tsbridge.tailscale.default_tags" = lib.concatStringsSep "," cfg.defaultTags;
        })
        // (lib.optionalAttrs (cfg.metricsAddr != null) {
          "tsbridge.global.metrics_addr" = cfg.metricsAddr;
        })
        // (lib.optionalAttrs (cfg.writeTimeout != null) {
          "tsbridge.global.write_timeout" = cfg.writeTimeout;
        });

      # tsbridge should only be in a single network and not be added to others by integations (e.g. socket-proxy)
      # Otherwise we lose the ability to assign static ip (only works with single bridge network)
      network = lib.mkForce reverseProxyCfg.network.name;

      alloy.enable = true;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "tailscale";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "si:tailscale";
      };
    };
  };
}
