{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "monitoring";
  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";

  yaml = pkgs.formats.yaml {};
  ini = pkgs.formats.ini {};

  grafanaName = "grafana";
  lokiName = "loki";
  prometheusName = "prometheus";
  alloyName = "alloy";
  podmanExporterName = "podman-exporter";

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
      config = lib.mkOption {
        type = yaml.type;
        default = {};
        apply = yaml.generate "prometheus_config.yml";
        description = ''
          Configuration for Prometheus.
          A default configuration will be automatically provided by this monitoring module.

          See <https://prometheus.io/docs/prometheus/latest/configuration/configuration/>
        '';
      };
    };
    podmanExporter.enable =
      lib.mkEnableOption "Podman Metrics Exporter"
      // {
        default = true;
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

      prometheus.config = lib.mkMerge [
        (import ./prometheus_config.nix)
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
    };

    services.podman.containers = {
      ${grafanaName} = lib.mkIf cfg.grafana.enable {
        image = "docker.io/grafana/grafana:12.1.1";
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
          category = "Monitoring";
          name = "Grafana";
          settings = {
            description = "Monitoring & Observability Platform";
            icon = "grafana";
            widget.type = "grafana";
          };
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
          category = "Monitoring";
          name = "Loki";
          settings = {
            description = "Log Aggregation";
            icon = "loki";
          };
        };
      };

      ${alloyName} = let
        configDst = "/etc/alloy/config.alloy";
      in
        lib.mkIf cfg.alloy.enable {
          image = "docker.io/grafana/alloy:v1.10.2";
          volumes = [
            "${cfg.alloy.config}:${configDst}"
          ];
          exec = "run --server.http.listen-addr=0.0.0.0:${toString cfg.alloy.port} --storage.path=/var/lib/alloy/data ${configDst}";

          stack = stackName;
          inherit (cfg.alloy) port;
          traefik.name = alloyName;
          homepage = {
            category = "Monitoring";
            name = "Alloy";
            settings = {
              description = "Telemetry Collector";
              icon = "alloy";
            };
          };
        };

      ${prometheusName} = let
        configDst = "/etc/prometheus/prometheus.yml";
      in
        lib.mkIf cfg.prometheus.enable {
          image = "docker.io/prom/prometheus:v3.6.0";
          exec = "--config.file=${configDst}";
          user = config.nps.defaultUid;
          volumes = [
            "${storage}/prometheus/data:/prometheus"
            "${cfg.prometheus.config}:${configDst}"
          ];

          port = cfg.prometheus.port;
          stack = stackName;
          traefik.name = "prometheus";
          homepage = {
            category = "Monitoring";
            name = "Prometheus";
            settings = {
              description = "Metrics & Monitoring";
              icon = "prometheus";
              widget.type = "prometheus";
            };
          };
        };

      ${podmanExporterName} = lib.mkIf cfg.podmanExporter.enable {
        image = "quay.io/navidys/prometheus-podman-exporter:v1.18.1";
        volumes = [
          "${config.nps.socketLocation}:/var/run/podman/podman.sock"
        ];
        environment.CONTAINER_HOST = "unix:///var/run/podman/podman.sock";
        user = config.nps.defaultUid;
        extraPodmanArgs = ["--security-opt=label=disable"];

        stack = stackName;
      };
    };
  };
}
