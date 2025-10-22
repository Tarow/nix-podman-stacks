{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "crowdsec";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml {};

  category = "Network & Administration";
  displayName = "CrowdSec";
  description = "Collaborative Security Threat Prevention";

  timer = {
    Timer = {
      OnCalendar = "01:30";
      Persistent = true;
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };
  job = {
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe (
        pkgs.writeShellScriptBin "crowdsec-update" (
          [
            "hub update"
            "hub upgrade"
            "collections upgrade -a"
            "parsers upgrade -a"
            "scenarios upgrade -a"
          ]
          |> lib.concatMapStringsSep "\n" (c: "${lib.getExe pkgs.podman} exec ${name} cscli " + c)
        )
      );
    };
  };
in {
  imports =
    [
      # Create the `useSocketProxy` option
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {
        stack = name;
      })
    ]
    ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      default = {};
      description = ''
        Configuration settings for Crowdsec.
        Will be provided as the `config.yaml.local` file.

        See <https://docs.crowdsec.net/docs/configuration/crowdsec_configuration/>

      '';
      apply = yaml.generate "config.yaml.local";
    };
    collections = lib.mkOption {
      type = lib.types.separatedString " ";
      default = "";
      example = "LePresidente/adguardhome crowdsecurity/aws-console";
      description = ''
        Collections to install. Will be passed as the `COLLECTIONS` environment variable.

        See <https://app.crowdsec.net/hub/collections>
      '';
    };
    acquisSettings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        freeformType = yaml.type;
        options = {
          source = lib.mkOption {
            type = lib.types.str;
            description = "Which type of datasource to use.";
            example = "docker";
          };
          log_level = lib.mkOption {
            type = lib.types.str;
            default = "info";
            description = "Log level to use in the datasource";
          };
          labels = lib.mkOption {
            type = lib.types.submodule {
              freeformType = yaml.type;
              options = {
                type = lib.mkOption {
                  type = lib.types.str;
                };
              };
            };
            default = {};
            description = ''
              A map of labels to add to the event. The type label is mandatory, and used by the Security Engine to choose which parser to use.

              See <https://docs.crowdsec.net/docs/next/log_processor/data_sources/intro#labels>
            '';
          };
        };
      });
      default = {};
      description = ''
        Acquisitions settings for Crowdsec.
        Each attribute set value will be mapped to an acquis configuration and mounted into the `/etc/crowdsec/acquis.d` directory.

        See <https://docs.crowdsec.net/docs/next/log_processor/data_sources/intro> for all available options.
      '';
      apply = settings:
        settings
        |> lib.mapAttrs (
          name: settings:
            settings
            // lib.optionalAttrs (settings.source == "docker" && cfg.useSocketProxy) {
              docker_host = config.nps.stacks.docker-socket-proxy.address;
            }
        )
        |> lib.mapAttrs (name: settings: yaml.generate "${name}-acquis.yaml" settings);
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/crowdsecurity/crowdsec/blob/master/docker/README.md#environment-variables>
      '';
      example = {
        SOME_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        FOO = "bar";
      };
    };
    enableGrafanaDashboard = lib.mkEnableOption "Grafana Dashboard";
    enablePrometheusExport = lib.mkEnableOption "Prometheus Export";
    # useSocketProxy option is configured by the imported module
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.monitoring.prometheus.settings = lib.mkIf cfg.enablePrometheusExport {
      scrape_configs = [
        {
          job_name = "crowdsec";
          honor_timestamps = true;
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [
            {
              targets = [(name + ":6060")];
              labels = {machine = "lapi";};
            }
          ];
        }
      ];
    };
    nps.stacks.monitoring.grafana.dashboards = lib.optional cfg.enableGrafanaDashboard ./grafana_dashboard.json;

    nps.stacks.${name} = {
      collections = "crowdsecurity/http-cve crowdsecurity/whitelist-good-actors";
      settings = {
        prometheus = {
          enabled = cfg.enablePrometheusExport;
          level = "full";
          listen_addr = "0.0.0.0";
          listen_port = 6060;
        };
      };
    };

    systemd.user = {
      timers."crowdsec-upgrade" = timer;
      services."crowdsec-upgrade" = job;
    };

    services.podman.containers.${name} = {
      image = "docker.io/crowdsecurity/crowdsec:v1.7.2";
      volumes =
        [
          "${storage}/db:/var/lib/crowdsec/data"
          "${storage}/config:/etc/crowdsec"
          "${cfg.settings}:/etc/crowdsec/config.yaml.local"
        ]
        ++ (lib.mapAttrsToList (name: file: "${file}:/etc/crowdsec/acquis.d/${name}.yaml") cfg.acquisSettings);
      environment = let
        utils = pkgs.callPackage ../utils.nix {inherit config;};
      in {
        COLLECTIONS = utils.escapeOnDemand ''"${cfg.collections}"'';
        UID = config.nps.defaultUid;
        GID = config.nps.defaultGid;
      };
      extraEnv = cfg.extraEnv;

      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "crowdsec";
          widget = {
            type = "crowdsec";
            url = "http://${name}:8080";
          };
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:crowdsec";
      };
    };
  };
}
