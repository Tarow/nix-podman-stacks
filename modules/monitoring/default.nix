{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "monitoring";
  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";

  category = "Monitoring";
  grafanaDescription = "Monitoring & Observability Platform";
  grafanaDisplayName = "Grafana";
  lokiDescription = "Log Aggregation";
  lokiDisplayName = "Loki";
  alloyDescription = "Telemetry Collector";
  alloyDisplayName = "Alloy";
  prometheusDescription = "Metrics & Monitoring";
  prometheusDisplayName = "Prometheus";
  podmanExporterDescription = "Podman Metric Exporter";
  podmanExporterDisplayName = "Podman Prometheus Exporter";
  alertmanagerDescription = "Prometheus Alert Handling";
  alertmanagerDisplayName = "Alertmanager";
  alertmanagerNtfyDescription = "Forward Alerts to ntfy";
  alertmanagerNtfyDisplayName = "alertmanager-ntfy";

  yaml = pkgs.formats.yaml {};
  ini = pkgs.formats.ini {};

  grafanaName = "grafana";
  lokiName = "loki";
  prometheusName = "prometheus";
  alloyName = "alloy";
  podmanExporterName = "podman-exporter";
  alertmanagerName = "alertmanager";
  alertmanagerNtfyName = "alertmanager-ntfy";

  dashboardPath = "/var/lib/grafana/dashboards";

  dashboards = pkgs.runCommandLocal "grafana-dashboards-dir" {} ''
    mkdir -p "$out"
    for f in ${lib.concatStringsSep " " cfg.grafana.dashboards}; do
      baseName=$(basename "$f")
      cp "$f" "$out/$baseName"
    done
  '';

  lokiUrl = "http://${lokiName}:${toString cfg.loki.port}";
  prometheusUrl = "http://${prometheusName}:${toString cfg.prometheus.port}";

  dockerHost =
    if cfg.alloy.useSocketProxy
    then config.nps.stacks.docker-socket-proxy.address
    else "unix:///var/run/docker.sock";
in {
  imports =
    [
      ./extension.nix
      # Create the `alloy.useSocketProxy` option
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {
        stack = stackName;
        container = alloyName;
        subPath = alloyName;
      })
    ]
    ++ import ../mkAliases.nix config lib stackName [
      grafanaName
      lokiName
      prometheusName
      alloyName
      podmanExporterName
    ];

  options.nps.stacks.${stackName} = {
    enable =
      lib.mkEnableOption stackName
      // {
        description = ''
          Enable the ${stackName} stack.
          This stack provides monitoring services including Grafana, Loki, Alloy, and Prometheus.
          Configuration files for each service will be provided automatically to work out of the box.
        '';
      };
    grafana = {
      enable =
        lib.mkEnableOption "Grafana"
        // {
          default = true;
        };
      dashboardProvider = lib.mkOption {
        type = yaml.type;
        default = import ./dashboard_provider.nix dashboardPath;
        apply = yaml.generate "dashboard_provider.yml";
        description = ''
          Dashboard provider configuration for Grafana.
        '';
        readOnly = true;
        visible = false;
      };
      dashboards = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = ''
          List of paths to Grafana dashboard JSON files.
        '';
      };
      datasources = lib.mkOption {
        type = yaml.type;
        apply = yaml.generate "grafana_datasources.yml";
        description = ''
          Datasource configuration for Grafana.
          Loki and Prometheus datasources will be automatically configured.
        '';
      };
      settings = lib.mkOption {
        type = ini.type;
        default = {};
        apply = ini.generate "grafana.ini";
        description = ''
          Settings for Grafana.
          Will be written to the 'grafana.ini' file.
          See <https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#configure-grafana>
        '';
      };
      oidc = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
            and setup the necessary configuration.

            For details, see:

            - <https://www.authelia.com/integration/openid-connect/clients/grafana/>
            - <https://docs.mealie.io/documentation/getting-started/authentication/oidc-v2/>
            - <https://docs.mealie.io/documentation/getting-started/installation/backend-config/#openid-connect-oidc>
          '';
        };
        clientSecretFile = lib.mkOption {
          type = lib.types.str;
          description = ''
            The file containing the client secret for the OIDC client that will be registered in Authelia.
          '';
        };
        clientSecretHash = lib.mkOption {
          type = lib.types.str;
          description = ''
            The hashed client_secret. Will be set in the Authelia client config.
            For examples on how to generate a client secret, see

            <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
          '';
        };
        adminGroup = lib.mkOption {
          type = lib.types.str;
          default = "${grafanaName}_admin";
          description = "Users of this group will be assigned the Grafana 'Admin' role.";
        };
        userGroup = lib.mkOption {
          type = lib.types.str;
          default = "${grafanaName}_user";
          description = "Users of this group will be assigned the Grafana 'Viewer' role.";
        };
      };
    };
    loki = {
      enable =
        lib.mkEnableOption "Loki"
        // {
          default = true;
        };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3100;
        visible = false;
      };
      config = lib.mkOption {
        type = yaml.type;
        default = {};
        apply = yaml.generate "loki_config.yaml";
        description = ''
          Configuration for Loki.
          A default configuration will be automatically provided by this monitoring module.

          See <https://grafana.com/docs/loki/latest/configuration/>
        '';
      };
    };
    alloy = {
      enable =
        lib.mkEnableOption "Alloy"
        // {
          default = true;
        };
      port = lib.mkOption {
        type = lib.types.port;
        default = 12345;
        visible = false;
      };
      config = lib.mkOption {
        type = lib.types.lines;
        apply = pkgs.writeText "config.alloy";
        description = ''
          Configuration for Alloy.
          A default configuration will be automatically provided by this monitoring module.
          The default configuration will ship logs of all containers that set the `alloy.enable=true` option to Loki.
          Multiple definitions of this option will be merged together into a single file.

          See <https://grafana.com/docs/alloy/latest/get-started/configuration-syntax/>
        '';
      };
    };
    prometheus = {
      enable =
        lib.mkEnableOption "Prometheus"
        // {
          default = true;
        };
      port = lib.mkOption {
        type = lib.types.port;
        default = 9090;
        visible = false;
      };
      settings = lib.mkOption {
        type = yaml.type;
        default = {};
        apply = yaml.generate "prometheus_config.yml";
        description = ''
          Configuration for Prometheus.
          A default configuration will be automatically provided by this monitoring module.

          See <https://prometheus.io/docs/prometheus/latest/configuration/configuration/>
        '';
      };
      rules = lib.mkOption {
        type = yaml.type;
        default = {};
        description = ''
          Alerting rule configuration for Prometheus.
          If provided, the rules will added to the `rule_file` setting.

          See <https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/>
        '';
      };
    };
    podmanExporter.enable = lib.mkEnableOption "Podman Metrics Exporter" // {default = true;};
    alertmanager = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable the Alertmanager.

          When setting `alertmanager.ntfy.enable`, a route and receiver configuration will be setup for ntfy.
          If using without ntfy, you will have to provide your own route and receiver configurations via the `settings` option
          for Alertmanager to startup correctly.
        '';
      };
      settings = lib.mkOption {
        type = yaml.type;
        apply = yaml.generate "alertmanager.yml";
        default = {};
        description = ''
          Alertmanager configuration. Will be provided as the `alertmanager.yml`.

          See <https://prometheus.io/docs/alerting/latest/configuration/>
        '';
      };
      ntfy = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.nps.stacks.ntfy.enable;
          defaultText = lib.literalExpression ''config.nps.stacks.ntfy.enable'';
          description = ''
            Whether to setup and configure alertmanager-ntfy.
            This allows alerts to be forwarded to ntfy.

            See <https://github.com/alexbakker/alertmanager-ntfy>
          '';
        };
        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Path to the file containing the token that is used for authentication against the ntfy service.
            Only required if ntfy is configured to require authentication.
          '';
        };
        settings = lib.mkOption {
          type = yaml.type;
          apply = yaml.generate "config.yml";
          default = {};
          description = ''
            alertmanager-ntfy configuration. Will be provided as the `config.yml`.

            See <https://github.com/alexbakker/alertmanager-ntfy/pkgs/container/alertmanager-ntfy#configuration>
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf (cfg.grafana.oidc.enable) {
      ${cfg.grafana.oidc.adminGroup} = {};
      ${cfg.grafana.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.grafana.oidc.enable {
      oidc.clients.${grafanaName} = {
        client_name = "Grafana";
        client_secret = cfg.grafana.oidc.clientSecretHash;
        public = false;
        authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
        claims_policy = grafanaName;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${grafanaName}.traefik.serviceUrl}/login/generic_oauth"
        ];
      };

      # See <https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/#restore-functionality-prior-to-claims-parameter>
      settings.identity_providers.oidc.claims_policies.${grafanaName}.id_token = [
        "email"
        "name"
        "groups"
        "preferred_username"
      ];
    };

    nps.stacks.${stackName} = {
      grafana = {
        dashboards = lib.optional cfg.podmanExporter.enable ./dashboards/podman-exporter.json;
        datasources = import ./grafana_datasources.nix lokiUrl prometheusUrl;
      };

      loki.config = import ./loki_local_config.nix cfg.loki.port;
      alloy.config = import ./alloy_config.nix lokiUrl dockerHost;

      prometheus.settings = lib.mkMerge [
        (import ./prometheus_config.nix)
        (lib.mkIf cfg.alertmanager.enable {
          alerting = {
            alertmanagers = [
              {
                static_configs = [{targets = [(alertmanagerName + ":9093")];}];
                scheme = "http";
                timeout = "10s";
                api_version = "v2";
              }
            ];
          };
        })
        (lib.mkIf (cfg.prometheus.rules != {}) {
          rule_files = ["/etc/prometheus/rules.yml"];
        })
        (lib.mkIf cfg.podmanExporter.enable {
          scrape_configs = [
            {
              job_name = "podman";
              honor_timestamps = true;
              metrics_path = "/metrics";
              scheme = "http";
              static_configs = [{targets = [(podmanExporterName + ":9882")];}];
            }
          ];
        })
      ];

      alertmanager = lib.mkIf cfg.alertmanager.enable {
        settings = lib.mkIf cfg.alertmanager.ntfy.enable {
          route = {
            receiver = "ntfy";
            repeat_interval = lib.mkDefault "4h";
            group_by = ["alertname"];
          };
          receivers = [
            {
              name = "ntfy";
              webhook_configs = [
                {
                  url = "http://${alertmanagerNtfyName}:8000/hook";
                }
              ];
            }
          ];
        };
        ntfy.settings = lib.mkIf cfg.alertmanager.ntfy.enable {
          http.addr = ":8000";
          ntfy = {
            baseurl = "http://${config.nps.containers.ntfy.traefik.serviceAddressInternal}";

            notification = {
              topic = lib.mkDefault "alertmanager";
              priority = lib.mkDefault "default";
              templates = {
                title = lib.mkDefault ''{{ if eq .Status "resolved" }}Resolved: {{ end }}{{ index .Annotations "summary" }}'';
                description = lib.mkDefault ''{{ index .Annotations "description" }}'';
              };
            };
          };
        };
      };
    };

    services.podman.containers = {
      ${grafanaName} = lib.mkIf cfg.grafana.enable {
        image = "docker.io/grafana/grafana:12.2.0";
        user = config.nps.defaultUid;
        volumes = [
          "${storage}/grafana/data:/var/lib/grafana"
          "${cfg.grafana.settings}:/etc/grafana/grafana.ini"
          "${cfg.grafana.datasources}:/etc/grafana/provisioning/datasources/datasources.yaml"
          "${cfg.grafana.dashboardProvider}:/etc/grafana/provisioning/dashboards/provider.yml"
          "${dashboards}:${dashboardPath}"
        ];

        environment = lib.optionalAttrs (!cfg.grafana.oidc.enable) {
          GF_AUTH_ANONYMOUS_ENABLED = "true";
          GF_AUTH_ANONYMOUS_ORG_ROLE = "Admin";
          GF_AUTH_DISABLE_LOGIN_FORM = "true";
        };

        extraEnv = let
          autheliaUrl = config.nps.containers.authelia.traefik.serviceUrl;
        in
          lib.optionalAttrs (cfg.grafana.oidc.enable) {
            GF_SERVER_ROOT_URL = cfg.containers.${grafanaName}.traefik.serviceUrl;
            GF_AUTH_GENERIC_OAUTH_ENABLED = true;
            GF_AUTH_GENERIC_OAUTH_NAME = "Authelia";
            GF_AUTH_GENERIC_OAUTH_ICON = "signin";
            GF_AUTH_GENERIC_OAUTH_CLIENT_ID = grafanaName;
            GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET.fromFile = cfg.grafana.oidc.clientSecretFile;
            GF_AUTH_GENERIC_OAUTH_SCOPES = "openid,profile,email,groups";
            GF_AUTH_GENERIC_OAUTH_EMPTY_SCOPES = false;
            GF_AUTH_GENERIC_OAUTH_AUTH_URL = "${autheliaUrl}/api/oidc/authorization";
            GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "${autheliaUrl}/api/oidc/token";
            GF_AUTH_GENERIC_OAUTH_API_URL = "${autheliaUrl}/api/oidc/userinfo";
            GF_AUTH_GENERIC_OAUTH_USE_PKCE = true;
            GF_AUTH_GENERIC_OAUTH_LOGIN_ATTRIBUTE_PATH = "preferred_username";
            GF_AUTH_GENERIC_OAUTH_GROUPS_ATTRIBUTE_PATH = "groups";
            GF_AUTH_GENERIC_OAUTH_EMAIL_ATTRIBUTE_NAME = "email";
            GF_AUTH_GENERIC_OAUTH_NAME_ATTRIBUTE_PATH = "name";
            GF_AUTH_GENERIC_OAUTH_ALLOW_ASSIGN_GRAFANA_ADMIN = true;
            # Quadlet Generator seems to not handle the single quotes too well, pass fromFile instead
            GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH.fromFile = pkgs.writeText "role_attribute_path" ''contains(groups[*], '${cfg.grafana.oidc.adminGroup}') && 'Admin' ||  contains(groups[*], '${cfg.grafana.oidc.userGroup}') && 'Viewer' || 'None' '';
          };

        port = 3000;
        stack = stackName;
        traefik.name = grafanaName;
        homepage = {
          inherit category;
          name = grafanaDisplayName;
          settings = {
            description = grafanaDescription;
            icon = "grafana";
            widget.type = "grafana";
          };
        };
        glance = {
          inherit category;
          description = grafanaDescription;
          name = grafanaDisplayName;
          id = grafanaName;
          icon = "di:grafana";
        };
      };

      ${lokiName} = lib.mkIf cfg.loki.enable {
        image = "docker.io/grafana/loki:3.5.5";
        exec = "-config.file=/etc/loki/local-config.yaml";
        user = config.nps.defaultUid;
        volumes = [
          "${storage}/loki/data:/loki"
          "${cfg.loki.config}:/etc/loki/local-config.yaml"
        ];

        stack = stackName;
        homepage = {
          inherit category;
          name = lokiDisplayName;
          settings = {
            description = lokiDescription;
            icon = "loki";
          };
        };
        glance = {
          inherit category;
          description = lokiDescription;
          name = lokiDisplayName;
          id = lokiName;
          icon = "di:loki";
        };
      };

      ${alloyName} = let
        configDst = "/etc/alloy/config.alloy";
      in
        lib.mkIf cfg.alloy.enable {
          image = "docker.io/grafana/alloy:v1.11.1";
          volumes = [
            "${cfg.alloy.config}:${configDst}"
          ];
          exec = "run --server.http.listen-addr=0.0.0.0:${toString cfg.alloy.port} --storage.path=/var/lib/alloy/data ${configDst}";

          stack = stackName;
          inherit (cfg.alloy) port;
          traefik.name = alloyName;
          homepage = {
            inherit category;
            name = alloyDisplayName;
            settings = {
              description = alloyDescription;
              icon = "alloy";
            };
          };
          glance = {
            inherit category;
            description = alloyDescription;
            name = alloyDisplayName;
            id = alloyName;
            icon = "di:alloy";
          };
        };

      ${prometheusName} = let
        configDst = "/etc/prometheus/prometheus.yml";
      in
        lib.mkIf cfg.prometheus.enable {
          image = "docker.io/prom/prometheus:v3.6.0";
          exec = "--config.file=${configDst}";
          user = config.nps.defaultUid;
          volumes =
            [
              "${storage}/prometheus/data:/prometheus"
              "${cfg.prometheus.settings}:${configDst}"
            ]
            ++ lib.optional (cfg.prometheus.rules != {}) "${yaml.generate "rules.yml" cfg.prometheus.rules}:/etc/prometheus/rules.yml";

          port = cfg.prometheus.port;
          stack = stackName;
          traefik.name = "prometheus";
          homepage = {
            inherit category;
            name = prometheusDisplayName;
            settings = {
              description = prometheusDescription;
              icon = "prometheus";
              widget.type = "prometheus";
            };
          };
          glance = {
            inherit category;
            description = prometheusDescription;
            name = prometheusDisplayName;
            id = prometheusName;
            icon = "di:prometheus";
          };
        };

      ${podmanExporterName} = lib.mkIf cfg.podmanExporter.enable {
        image = "quay.io/navidys/prometheus-podman-exporter:v1.19.0";
        volumes = [
          "${config.nps.socketLocation}:/var/run/podman/podman.sock"
        ];
        environment.CONTAINER_HOST = "unix:///var/run/podman/podman.sock";
        user = config.nps.defaultUid;
        extraPodmanArgs = ["--security-opt=label=disable"];

        stack = stackName;
        homepage = {
          inherit category;
          name = podmanExporterDisplayName;
          settings = {
            description = podmanExporterDescription;
            icon = "podman";
          };
        };
        glance = {
          inherit category;
          description = podmanExporterDescription;
          name = podmanExporterDisplayName;
          id = podmanExporterName;
          icon = "di:podman";
        };
      };

      ${alertmanagerName} = lib.mkIf cfg.alertmanager.enable {
        image = "docker.io/prom/alertmanager:v0.28.1";
        user = config.nps.defaultUid;
        volumes = [
          "${cfg.alertmanager.settings}:/config/alertmanager.yml"
          "${storage}/${alertmanagerName}:/data"
        ];
        exec = "--config.file=/config/alertmanager.yml --storage.path=/data";

        stack = stackName;
        port = 9093;
        traefik.name = alertmanagerName;

        homepage = {
          inherit category;
          name = alertmanagerDisplayName;
          settings = {
            description = alertmanagerDescription;
            icon = "alertmanager";
          };
        };
        glance = {
          inherit category;
          description = alertmanagerDescription;
          name = alertmanagerDisplayName;
          id = alertmanagerName;
          icon = "di:alertmanager";
        };
      };

      ${alertmanagerNtfyName} = lib.mkIf (cfg.alertmanager.enable && cfg.alertmanager.ntfy.enable) {
        image = "ghcr.io/alexbakker/alertmanager-ntfy:1.0.2";
        volumes = ["${cfg.alertmanager.ntfy.settings}:/etc/config.yml"];
        templateMount = lib.optional (cfg.alertmanager.ntfy.tokenFile != null) {
          templatePath = yaml.generate "auth.yaml" {ntfy.auth.token = "{{file.Read `${cfg.alertmanager.ntfy.tokenFile}`}}";};
          destPath = "/etc/auth.yml";
        };
        exec = "--configs /etc/config.yml,/etc/auth.yml";

        # Join both ntfy and monitoring network
        stack = stackName;
        network = ["ntfy"];

        homepage = {
          inherit category;
          name = alertmanagerNtfyDisplayName;
          settings = {
            description = alertmanagerNtfyDescription;
            icon = "ntfy";
          };
        };
        glance = {
          inherit category;
          description = alertmanagerNtfyDescription;
          name = alertmanagerNtfyDisplayName;
          id = alertmanagerNtfyName;
          icon = "di:ntfy";
        };
      };
    };
  };
}
