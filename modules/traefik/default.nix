{
  lib,
  config,
  pkgs,
  ...
}: let
  name = "traefik";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml {};

  category = "Network & Administration";
  description = "Reverse Proxy";
  displayName = "Traefik";

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
          Wheter to enable Traefik.
          The Traefik stack ships preconfigured with a dynamic and static configuration.
        '';
      };
    domain = lib.options.mkOption {
      type = lib.types.str;
      description = "Base domain handled by Traefik";
    };
    ip4 = lib.options.mkOption {
      type = lib.types.str;
      readOnly = true;
      visible = false;
      description = "IPv4 address of the Traefik container in the Podman bridge network";
      default = "10.80.0.2";
    };
    network = {
      name = lib.options.mkOption {
        type = lib.types.str;
        description = "Network name for Podman bridge network. Will be used by the Traefik Docker provider";
        default = "traefik-proxy";
      };
      subnet = lib.options.mkOption {
        type = lib.types.str;
        readOnly = true;
        visible = false;
        description = "Subnet of the Podman bridge network";
        default = "10.80.0.0/24";
      };
      gateway = lib.options.mkOption {
        type = lib.types.str;
        readOnly = true;
        visible = false;
        description = "Gateway of the Podman bridge network";
        default = "10.80.0.1";
      };
      ipRange = lib.options.mkOption {
        type = lib.types.str;
        readOnly = true;
        visible = false;
        description = "IP-Range of the Podman bridge network";
        default = "10.80.0.10-10.80.0.255";
      };
    };
    staticConfig = lib.options.mkOption {
      type = yaml.type;
      apply = yaml.generate "traefik.yml";
      description = ''
        Static configuration for Traefik.
        By default, for the configured domain, a wildcard certificate will be requested from Let's Encrypt
        and used for all services that are registered with Traefik.
        By default Cloudflare with DNS challenge will be used to request the certificate.
        This requires the 'CF_DNS_API_TOKEN' environment variable to be present, e.g. by providing it via the `extraEnv` option.

        The DNS provider as well as any other settings can be overwritten.
        For an example see <https://github.com/Tarow/nix-podman-stacks/blob/main/examples/traefik-dns-provider.nix>
      '';
    };
    dynamicConfig = lib.options.mkOption {
      type = yaml.type;
      default = {};
      description = ''
        Dynamic configuration for Traefik.
        By default, the module will setup two middlewares: `private` & `public`.
        The private middleware (applied by default to all services) will only allow access from internal networks.
        The public middleware will allow access from the internet. It will be configured
        with a rate limit, security headers and a geoblock plugin (if enabled). If enabled, Crowdsec will also
        be added to the `public` middleware chain.
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).
      '';
      example = {
        CF_DNS_API_TOKEN = {
          fromFile = "/run/secrets/secret_name";
        };
        TRAEFIK_LOG_LEVEL = "ERROR";
      };
    };
    geoblock = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable the geoblock plugin for Traefik.
          This will block access to the services based on the country code of the request.
          The plugin uses the IP2Location database to determine the country code.
          If enabled, the geoblock will be used in the `public` middleware,
          allowing only requests from the allowed countries.
        '';
      };
      allowedCountries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          List of allowed country codes (ISO 3166-1 alpha-2 format)
          See <https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements>
        '';
      };
    };
    crowdsec = {
      enableLogCollection = lib.mkOption {
        type = lib.types.bool;
        default = config.nps.stacks.crowdsec.enable;
        defaultText = lib.literalExpression ''config.nps.stacks.crowdsec.enable'';
        description = ''
          Whether logs from Traefik should be collected by CrowdSec.
          Enabling this will configure the acquis settings for CrowdSec.
        '';
      };
      middleware = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.nps.stacks.crowdsec.enable;
          defaultText = lib.literalExpression ''config.nps.stacks.crowdsec.enable'';
          description = ''
            Whether to setup a Traefik middleware.
            Make sure to also configure the `bouncerKeyFile` option.
          '';
        };
        bouncerKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Path to the file containing the key for the Traefik bouncer.
            If this is set, a Bouncer will be setup in CrowdSec. Also a new `crowdsec` middleware will be registered in Traefik and added to the `public` chain.
            This will block requests to exposed services that are detected as malicious by Crowdsec.
          '';
        };
      };
    };
    enablePrometheusExport = lib.mkEnableOption "Prometheus Export";
    enableGrafanaMetricsDashboard = lib.mkEnableOption "Grafana Metrics Dashboard";
    enableGrafanaAccessLogDashboard = lib.mkEnableOption "Grafana Access Log Dashboard";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.crowdsec.middleware.enable || config.nps.stacks.crowdsec.enable;
        message = "The option 'nps.stacks.${name}.crowdsec.middleware.enable' is set to true, but the 'crowdsec' stack is not enabled.";
      }
    ];

    nps.stacks.crowdsec = {
      collections = lib.mkIf cfg.crowdsec.enableLogCollection "crowdsecurity/traefik";
      acquisSettings.traefik = lib.mkIf cfg.crowdsec.enableLogCollection {
        source = "docker";
        container_name = [name];
        labels = {
          type = "traefik";
        };
      };
      containers.crowdsec = lib.mkIf cfg.crowdsec.middleware.enable {
        network = [cfg.network.name];
        extraEnv = {
          BOUNCER_KEY_TRAEFIK.fromFile = cfg.crowdsec.middleware.bouncerKeyFile;
        };
      };
    };
    nps.stacks.${name} = {
      staticConfig = lib.mkMerge [
        (import ./config/traefik.nix lib cfg.domain cfg.network.name)

        (lib.mkIf cfg.useSocketProxy {
          providers.docker.endpoint = config.nps.stacks.docker-socket-proxy.address;
        })

        (lib.mkIf cfg.enablePrometheusExport {
          entryPoints.metrics.address = ":9100";
          metrics.prometheus.entryPoint = "metrics";
        })
        (lib.mkIf cfg.crowdsec.middleware.enable {
          experimental.plugins.bouncer = {
            moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
            version = "v1.4.5";
          };
        })
      ];
      dynamicConfig = lib.mkMerge [
        (import ./config/dynamic.nix)

        (lib.mkIf cfg.geoblock.enable {
          http.middlewares = {
            public.chain.middlewares = lib.mkOrder 1100 ["geoblock"];
            geoblock.plugin.geoblock = {
              enabled = true;
              databaseFilePath = "/plugins/geoblock/IP2LOCATION-LITE-DB1.IPV6.BIN";
              allowedCountries = cfg.geoblock.allowedCountries;
              defaultAllow = false;
              allowPrivate = true;
              disallowedStatusCode = 403;
            };
          };
        })

        (lib.mkIf cfg.crowdsec.middleware.enable {
          http.middlewares = {
            public.chain.middlewares = lib.mkAfter ["crowdsec"];

            crowdsec.plugin.bouncer = {
              enabled = true;
              logLevel = "INFO";
              updateIntervalSeconds = 60;
              updateMaxFailure = 0;
              defaultDecisionSeconds = 60;
              httpTimeoutSeconds = 10;
              crowdsecMode = "live";
              crowdsecAppsecEnabled = false;
              crowdsecAppsecHost = "crowdsec:7422";
              crowdsecAppsecPath = "/";
              crowdsecAppsecFailureBlock = true;
              crowdsecAppsecUnreachableBlock = true;
              crowdsecAppsecBodyLimit = 10485760;
              crowdsecLapiKey = "{{ env `BOUNCER_KEY_TRAEFIK` }}";
              crowdsecLapiScheme = "http";
              crowdsecLapiHost = "crowdsec:8080";
              crowdsecLapiPath = "/";
              clientTrustedIPs = [
                "10.0.0.0/8"
                "172.16.0.0/12"
                "192.168.0.0/16"
              ];
            };
          };
        })
      ];
    };
    nps.stacks.monitoring = {
      grafana.dashboards =
        (lib.optional cfg.enableGrafanaAccessLogDashboard ./grafana/access_log_dashboard.json)
        ++ (lib.optional cfg.enableGrafanaMetricsDashboard ./grafana/metrics_dashboard.json);
      prometheus.settings.scrape_configs = lib.optional cfg.enablePrometheusExport {
        job_name = "traefik";
        honor_timestamps = true;
        metrics_path = "/metrics";
        scheme = "http";
        static_configs = [{targets = [(name + ":9100")];}];
      };
    };

    services.podman.networks.${cfg.network.name} = {
      driver = "bridge";
      subnet = cfg.network.subnet;
      gateway = cfg.network.gateway;
      extraConfig = {
        Network.IPRange = cfg.network.ipRange;
      };
    };

    services.podman.containers.${name} = rec {
      image = "docker.io/traefik:v3.6.1";

      socketActivation = [
        {
          port = 80;
          fileDescriptorName = "web";
        }
        {
          port = 443;
          fileDescriptorName = "websecure";
        }
      ];

      extraEnv =
        {
          BOUNCER_KEY_TRAEFIK = lib.mkIf cfg.crowdsec.middleware.enable {
            fromFile = cfg.crowdsec.middleware.bouncerKeyFile;
          };
        }
        // cfg.extraEnv;

      volumes = [
        "${storage}/letsencrypt:/letsencrypt"
        "${cfg.staticConfig}:/etc/traefik/traefik.yml:ro"
        "${yaml.generate "dynamic.yml" cfg.dynamicConfig}:/dynamic/config.yml"
        "${./config/IP2LOCATION-LITE-DB1.IPV6.BIN}:/plugins/geoblock/IP2LOCATION-LITE-DB1.IPV6.BIN"
      ];

      labels = {
        "traefik.http.routers.${traefik.name}.service" = "api@internal";
      };

      wantsContainer = lib.optional cfg.crowdsec.middleware.enable "crowdsec";

      # Traefik should only be in a single network and not be added to others by integations (e.g. socket-proxy)
      # Otherwise we lose the ability to assign static ip (only works with single bridge network)
      network = lib.mkForce cfg.network.name;
      ip4 = cfg.ip4;
      # For every container that we manage, add a NetworkAlias, so that connections to Traefik are possible
      # trough the internal podman network (no host-gateway required)
      extraConfig.Container.NetworkAlias =
        config.services.podman.containers
        |> lib.attrValues
        |> lib.filter (c: c.traefik.name != null)
        |> lib.map (c: c.traefik.serviceHost);

      traefik.name = name;
      alloy.enable = true;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          href = "https://${name}.${cfg.domain}";
          icon = "traefik";
          widget.type = "traefik";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:traefik";
      };
    };
  };
}
