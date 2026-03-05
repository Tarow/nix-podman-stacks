{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "netbird";
  dashboardName = "${stackName}-dashboard";
  serverName = "${stackName}-server";

  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";

  category = "Network & Administration";
  description = "Open Source Zero Trust Networking";
  displayName = "NetBird";

  yaml = pkgs.formats.yaml {};
  utils = pkgs.callPackage ../utils.nix {inherit config;};
in {
  imports = import ../mkAliases.nix config lib stackName [dashboardName serverName];

  options.nps.stacks.${stackName} = {
    enable = lib.mkEnableOption stackName;
    authSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the shared secret for relay authentication.
        Can be generated using `openssl rand -hex 32`.

        For details see <https://docs.netbird.io/selfhosted/configuration-files#server-settings>
      '';
    };
    storeEncryptionKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the 32-byte encryption key for sensitive data at rest.
        Can be generated using `openssl rand -base64 32`.

        For details see <https://docs.netbird.io/selfhosted/configuration-files#store-settings>
      '';
    };
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Netbird settings. Will be provided in the `configuration.yml`.
        The config will be templated using `gomplate`, so you can refer to secrets etc.

        For details see <https://docs.netbird.io/selfhosted/configuration-files#config-yaml>
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

          - <https://www.authelia.com/integration/openid-connect/clients/netbird/>
          - <https://docs.netbird.io/selfhosted/identity-providers>

          If disabled, the internal built-in usermanagement will be used.
          See <https://docs.netbird.io/selfhosted/identity-providers/local>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${stackName}_user";
        description = "Users of this group will be able to log in";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${stackName} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = stackName;
        require_pkce = true;
        pkce_challenge_method = "S256";
        consent_mode = "implicit";
        audience = [stackName];
        scopes = ["openid" "profile" "email" "groups" "offline_access"];
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${dashboardName}.traefik.serviceUrl}/nb-auth"
          "${cfg.containers.${dashboardName}.traefik.serviceUrl}/peers"
          "${cfg.containers.${dashboardName}.traefik.serviceUrl}/add-peers"
          "http://localhost"
          "http://localhost:5300"
        ];
        token_endpoint_auth_method = "client_secret_post";
      };

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
      # See <https://github.com/TwiN/gatus/issues/638>
      settings.identity_providers.oidc.authorization_policies.${stackName} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = "group:${cfg.oidc.userGroup}";
          }
        ];
      };

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

    nps.stacks.${stackName}.settings = let
      netbirdUrl = cfg.containers.${dashboardName}.traefik.serviceUrl;
      autheliaUrl = config.nps.containers.authelia.traefik.serviceUrl;
    in {
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
        image = "docker.io/netbirdio/dashboard:v2.33.0";

        extraEnv = {
          NETBIRD_MGMT_API_ENDPOINT = cfg.containers.${serverName}.traefik.serviceUrl;
          NETBIRD_MGMT_GRPC_API_ENDPOINT = cfg.containers.${serverName}.traefik.serviceUrl;

          AUTH_AUDIENCE =
            if cfg.oidc.enable
            then stackName
            else "netbird-dashboard";
          AUTH_CLIENT_ID =
            if cfg.oidc.enable
            then stackName
            else "netbird-dashboard";
          AUTH_CLIENT_SECRET = lib.mkIf cfg.oidc.enable {fromFile = cfg.oidc.clientSecretFile;};
          AUTH_AUTHORITY =
            if cfg.oidc.enable
            then config.nps.containers.authelia.traefik.serviceUrl
            else "${cfg.containers.${serverName}.traefik.serviceUrl}/oauth2";
          USE_AUTH0 = false;
          AUTH_SUPPORTED_SCOPES.fromFile = pkgs.writeText "scopes" "openid profile email groups offline_access";
          AUTH_REDIRECT_URI = "/nb-auth";
          AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
        };

        stack = stackName;
        port = 80;
        labels."traefik.http.routers.${dashboardName}.priority" = "1";
        traefik = {
          name = dashboardName;
          subDomain = stackName;
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
        image = "ghcr.io/netbirdio/netbird-server:0.66.2";
        ports = ["3478:3478/udp"];
        volumeMap.data = "${storage}/data:/var/lib/netbird";

        templateMount = [
          {
            templatePath = "${yaml.generate "netbird_config" cfg.settings}";
            destPath = "/etc/netbird/config.yaml";
          }
        ];

        exec = "--config /etc/netbird/config.yaml";

        stack = stackName;
        port = 80;

        labels = let
          grpcName = "${stackName}-grpc";
        in {
          # Backend router configured by standard extension, just override rule
          "traefik.http.routers.${serverName}.rule" = utils.escapeOnDemand "'Host(`${cfg.containers.${serverName}.traefik.serviceHost}`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`))'";

          # gRPC Router
          "traefik.http.routers.${grpcName}.rule" = utils.escapeOnDemand "'Host(`${cfg.containers.${serverName}.traefik.serviceHost}`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`))'";
          "traefik.http.routers.${grpcName}.tls" = "true";
          "traefik.http.routers.${grpcName}.service" = "${grpcName}";

          "traefik.http.services.${grpcName}.loadbalancer.server.port" = "80";
          "traefik.http.services.${grpcName}.loadbalancer.server.scheme" = "h2c";
        };

        traefik = {
          name = serverName;
          subDomain = stackName;
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
