{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "tsbridge";
  cfg = config.nps.stacks.${name};

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

    network = {
      name = lib.options.mkOption {
        type = lib.types.str;
        description = "Network name for Podman bridge network. tsbridge must share this network with containers it proxies.";
        default = "tsbridge-proxy";
      };
      subnet = lib.options.mkOption {
        type = lib.types.str;
        readOnly = true;
        visible = false;
        description = "Subnet of the Podman bridge network";
        default = "10.81.0.0/24";
      };
      gateway = lib.options.mkOption {
        type = lib.types.str;
        readOnly = true;
        visible = false;
        description = "Gateway of the Podman bridge network";
        default = "10.81.0.1";
      };
      ipRange = lib.options.mkOption {
        type = lib.types.str;
        readOnly = true;
        visible = false;
        description = "IP-Range of the Podman bridge network";
        default = "10.81.0.10-10.81.0.255";
      };
    };

    oauth = {
      clientIdEnvVar = lib.options.mkOption {
        type = lib.types.str;
        default = "TSBRIDGE_OAUTH_CLIENT_ID";
        description = ''
          Name of the environment variable containing the Tailscale OAuth client ID.
          Will be passed as tsbridge.oauth_client_id_env label.
        '';
      };
      clientSecretEnvVar = lib.options.mkOption {
        type = lib.types.str;
        default = "TSBRIDGE_OAUTH_CLIENT_SECRET";
        description = ''
          Name of the environment variable containing the Tailscale OAuth client secret.
          Will be passed as tsbridge.oauth_client_secret_env label.
        '';
      };
      clientIdFile = lib.options.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to file containing the Tailscale OAuth client ID.
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
      example = {
        TSBRIDGE_OAUTH_CLIENT_ID = {
          fromFile = "/run/secrets/tsbridge_oauth_client_id";
        };
        TSBRIDGE_OAUTH_CLIENT_SECRET = {
          fromFile = "/run/secrets/tsbridge_oauth_client_secret";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.oauth.clientIdFile != null && cfg.oauth.clientSecretFile != null;
        message = "tsbridge requires both oauth.clientIdFile and oauth.clientSecretFile to be set.";
      }
      {
        assertion = cfg.tailnetDomain != "";
        message = "tsbridge requires tailnetDomain to be set. Example: my-tailnet.ts.net";
      }
      {
        assertion = cfg.useSocketProxy -> config.nps.stacks.docker-socket-proxy.enable;
        message = "The option 'nps.stacks.${name}.useSocketProxy' is set to true, but the 'docker-socket-proxy' stack is not enabled.";
      }
    ];

    services.podman.networks.${cfg.network.name} = {
      driver = "bridge";
      subnet = cfg.network.subnet;
      gateway = cfg.network.gateway;
      extraConfig = {
        Network.IPRange = cfg.network.ipRange;
      };
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/jtdowney/tsbridge:latest";

      exec =
        "--provider docker"
        + lib.optionalString cfg.useSocketProxy
          " --docker-socket ${config.nps.stacks.docker-socket-proxy.address}";

      extraEnv =
        {
          "${cfg.oauth.clientIdEnvVar}" = {
            fromFile = cfg.oauth.clientIdFile;
          };
          "${cfg.oauth.clientSecretEnvVar}" = {
            fromFile = cfg.oauth.clientSecretFile;
          };
        }
        // cfg.extraEnv;

      volumes = [
        "${storage}/state:/state"
      ];

      labels =
        {
          "tsbridge.tailscale.oauth_client_id_env" = cfg.oauth.clientIdEnvVar;
          "tsbridge.tailscale.oauth_client_secret_env" = cfg.oauth.clientSecretEnvVar;
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

      network = [cfg.network.name];

      # tsbridge needs access to Docker socket to discover containers
      dependsOn = lib.mkIf cfg.useSocketProxy ["podman-docker-socket-proxy.service"];

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
