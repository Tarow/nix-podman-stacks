{
  config,
  lib,
  ...
}: let
  name = "pangolin-newt";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  displayName = "Pangolin Newt";
  description = "A tunneling client for Pangolin";
in {
  imports =
    [
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
    ]
    ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    enableGrafanaDashboard = lib.mkEnableOption "Grafana Dashboard";
    enablePrometheusExport = lib.mkEnableOption "Prometheus Export";

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).
      '';
      example = {
        PANGOLIN_ENDPOINT = {
          fromFile = "/run/secrets/secret_name";
        };
        NEWT_ID = {
          fromFile = "/run/secrets/secret_name";
        };
        NEWT_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        NEWT_ADMIN_ADDR = ":2112";
        LOG_LEVEL = "INFO";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.monitoring.grafana = lib.mkIf cfg.enableGrafanaDashboard {
      dashboards = [./grafana_dashboard.json];
      settings.panels.disable_sanitize_html = true;
    };
    nps.stacks.monitoring.prometheus.settings = lib.mkIf cfg.enablePrometheusExport {
      scrape_configs = [
        {
          job_name = "pangolin-newt";
          honor_timestamps = true;
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [{targets = [(name + ":2112")];}];
        }
      ];
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/fosrl/newt:1.11.0";
      extraEnv =
        {
          DOCKER_SOCKET = lib.mkIf (cfg.useSocketProxy) config.nps.stacks.docker-socket-proxy.address;
        }
        // lib.optionalAttrs cfg.enablePrometheusExport {
          NEWT_METRICS_PROMETHEUS_ENABLED = true;
        }
        // cfg.extraEnv;
      port = 2112;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "pangolin";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:pangolin";
      };
    };
  };
}
