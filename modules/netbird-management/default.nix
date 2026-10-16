{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "netbird-management";
  dashboardName = "${stackName}-dashboard";
  serverName = "${stackName}-server";

  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";

  category = "Network & Administration";
  description = "Open Source Zero Trust Networking";
  displayName = "NetBird Management";

  yaml = pkgs.formats.yaml {};
  traefikName = "netbird";
  netbirdUrl = cfg.containers.${dashboardName}.traefik.serviceUrl;
  idpName = "Authelia";
  clientId = stackName;
  grpcName = "${stackName}-grpc";
  serverRule = "Host(`${cfg.containers.${serverName}.traefik.serviceHost}`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`))";
  grpcRule = "Host(`${cfg.containers.${serverName}.traefik.serviceHost}`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`) || PathPrefix(`/management.ProxyService/`))";
  provisionScript = lib.getExe (pkgs.callPackage ./provision.nix {
    inherit stackName idpName clientId;
    autheliaIssuer = config.nps.containers.authelia.traefik.serviceUrl;
    adminProvisioning = cfg.adminProvisioning;
    provisionOidc = cfg.oidc.enable;
    clientSecretFile = cfg.oidc.clientSecretFile;
  });
in {
  imports = import ../mkAliases.nix config lib stackName [dashboardName serverName];

  options.nps.stacks.${stackName} = {
    enable = lib.mkEnableOption stackName;
    authSecretFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the relay authentication secret.";
    };
    storeEncryptionKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the 32-byte encryption key for stored data.";
    };
    settings = lib.mkOption {
      type = yaml.type;
      description = "NetBird server settings, templated with gomplate.";
    };
    adminProvisioning = {
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email for the initial NetBird owner account.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "NetBird Admin";
        description = "Display name for the initial NetBird owner account.";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "File containing the initial NetBird owner password.";
      };
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Authelia OIDC integration. The provider is registered only during NetBird's initial setup.";
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${stackName}_user";
        description = "Group allowed to log in.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.traefik.dynamicConfig.http = lib.mkIf (config.nps.stacks.traefik.provider == "file") {
      routers.${serverName}.priority = 100;
      routers.${grpcName} = {
        rule = grpcRule;
        priority = 100;
        service = grpcName;
        middlewares = lib.optional (!cfg.containers.${serverName}.expose) "private" ++ lib.optional cfg.containers.${serverName}.expose "public";
      };
      services.${grpcName}.loadBalancer.servers = [
        {
          url = "h2c://${serverName}:80";
        }
      ];
    };

    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${stackName} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = stackName;
        require_pkce = false;
        pkce_challenge_method = "";
        consent_mode = "implicit";
        audience = [stackName];
        scopes = ["openid" "profile" "email"];
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = ["${netbirdUrl}/oauth2/callback"];
        token_endpoint_auth_method = "client_secret_post";
        # NetBird's embedded Dex OIDC connector hard-requires a `name` claim, which
        # Authelia does not emit in the ID token by default.
        # See <https://github.com/netbirdio/netbird/issues/5143>
        claims_policy = stackName;
      };
      settings.identity_providers.oidc.authorization_policies.${stackName} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = "group:${cfg.oidc.userGroup}";
          }
        ];
      };

      settings.identity_providers.oidc.claims_policies.${stackName}.id_token = [
        "email"
        "email_verified"
        "preferred_username"
        "name"
        "groups"
      ];

      settings.identity_providers.oidc.cors = {
        allowed_origins_from_client_redirect_uris = true;
        endpoints = [
          "authorization"
          "token"
          "revocation"
          "introspection"
          "userinfo"
        ];
      };
    };

    nps.stacks.${stackName}.settings = {
      server = {
        listenAddress = ":80";
        exposedAddress = "${netbirdUrl}:443";
        stunPorts = [
          3478
        ];
        metricsPort = 9090;
        healthcheckAddress = ":9000";
        logLevel = "info";
        logFile = "console";

        authSecret = "{{ file.Read `${cfg.authSecretFile}`}}";
        dataDir = "/var/lib/netbird";

        auth = {
          issuer = "${netbirdUrl}/oauth2";
          signKeyRefreshEnabled = true;
          dashboardRedirectURIs = [
            "${netbirdUrl}/nb-auth"
            "${netbirdUrl}/nb-silent-auth"
          ];
          cliRedirectURIs = [
            "http://localhost:53000/"
          ];
        };

        reverseProxy = {
          trustedHTTPProxies = [
            config.nps.stacks.traefik.network.subnet
          ];
        };

        store = {
          engine = "sqlite";
          encryptionKey = "{{ file.Read `${cfg.storeEncryptionKeyFile}`}}";
        };
      };
    };

    services.podman.containers = {
      ${dashboardName} = {
        image = "docker.io/netbirdio/dashboard:v2.95.0";

        extraEnv = {
          NETBIRD_MGMT_API_ENDPOINT = cfg.containers.${serverName}.traefik.serviceUrl;
          NETBIRD_MGMT_GRPC_API_ENDPOINT = cfg.containers.${serverName}.traefik.serviceUrl;

          AUTH_AUDIENCE = "netbird-dashboard";
          AUTH_CLIENT_ID = "netbird-dashboard";
          AUTH_AUTHORITY = "${netbirdUrl}/oauth2";
          USE_AUTH0 = false;
          AUTH_SUPPORTED_SCOPES.fromFile = pkgs.writeText "scopes" "openid profile email groups";
          AUTH_REDIRECT_URI = "/nb-auth";
          AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
        };

        stack = stackName;
        port = 80;
        labels."traefik.http.routers.${dashboardName}.priority" = "1";
        traefik = {
          name = dashboardName;
          subDomain = traefikName;
        };
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "netbird";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = stackName;
          icon = "di:netbird";
        };
      };

      ${serverName} = {
        image = "ghcr.io/netbirdio/netbird-server:0.81.2";
        environment.NB_SETUP_PAT_ENABLED = true;
        ports = ["3478:3478/udp"];
        volumeMap.data = "${storage}/data:/var/lib/netbird";

        templateMount = [
          {
            templatePath = "${yaml.generate "netbird_config" cfg.settings}";
            destPath = "/etc/netbird/config.yaml";
          }
        ];

        exec = "--config /etc/netbird/config.yaml";
        extraConfig.Service.ExecStartPost = [provisionScript];
        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "bash -c '</dev/tcp/127.0.0.1/80'";
          HealthInterval = "5s";
          HealthTimeout = "3s";
          HealthRetries = 12;
          HealthStartPeriod = "5s";
          HealthOnFailure = "kill";
        };

        stack = stackName;
        port = 80;

        # The combined server shares its host with the dashboard, so restrict its
        # HTTP router to NetBird's documented backend paths. gRPC has a separate
        # router/service below because it requires h2c while these paths do not.
        traefik = {
          name = serverName;
          subDomain = traefikName;
          rule = serverRule;
        };
        labels = {
          "traefik.http.routers.${serverName}.priority" = "100";
          "traefik.http.routers.${grpcName}.rule" = grpcRule;
          "traefik.http.routers.${grpcName}.priority" = "100";
          "traefik.http.routers.${grpcName}.tls" = "true";
          "traefik.http.routers.${grpcName}.service" = grpcName;
          "traefik.http.services.${grpcName}.loadbalancer.server.port" = "80";
          "traefik.http.services.${grpcName}.loadbalancer.server.scheme" = "h2c";
        };
        glance = {
          inherit category;
          name = "Server";
          parent = stackName;
          icon = "di:netbird";
        };
      };
    };
  };
}
