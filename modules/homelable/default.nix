{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "homelable";
  backendName = "${name}-backend";
  mcpName = "${name}-mcp";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Network & Administration";
  description = "Homelab Infrastructure Visualizer";
  displayName = "Homelable";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    backendName
    mcpName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key used to sign session tokens.
        Can be generated with `openssl rand -hex 32`.

        See <https://github.com/Pouzor/homelable/blob/main/.env.example>
      '';
    };
    auth = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username for local authentication.";
      };
      passwordHashFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to the file containing the bcrypt hash of the local authentication password.
          Can be generated with:
          `python3 -c "import bcrypt; print(bcrypt.hashpw(b'yourpassword', bcrypt.gensalt()).decode())"`.

          Required unless `oidc.enable` is set to `true`.
        '';
      };
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:

          - <https://github.com/Pouzor/homelable/blob/main/docs/oidc-auth.md>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };
    mcp = {
      enable = lib.mkEnableOption "MCP server";
      apiKeyFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing the API key that authenticates AI clients
          against the MCP server (`MCP_API_KEY`).
          Can be generated with `openssl rand -hex 32`.
        '';
      };
      serviceKeyFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing the service key that authenticates the MCP
          server against the backend (`MCP_SERVICE_KEY`).
          Can be generated with `openssl rand -hex 32`.
        '';
      };
    };
    scannerRanges = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        List of CIDR ranges that will be scanned for devices.
      '';
      example = ["192.168.1.0/24" "10.0.0.0/24"];
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables for the backend container.
        Useful for features like deep scans, live view, the gethomepage widget
        or Proxmox/Zigbee/Z-Wave auto-sync.

        See <https://github.com/Pouzor/homelable/blob/main/.env.example>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.oidc.enable || cfg.auth.passwordHashFile != null;
        message = "nps.stacks.homelable: auth.passwordHashFile must be set unless oidc.enable is true.";
      }
    ];

    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        token_endpoint_auth_method = "client_secret_basic";
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/v1/auth/oidc/callback"
        ];
      };

      # Homelable doesn't support group based RBAC, restrict user-access on Authelia level
      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = "group:${cfg.oidc.userGroup}";
          }
        ];
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/pouzor/homelable-frontend:3.2.0";

        wantsContainer = [backendName];

        stack = name;
        port = 80;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "homelable";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:homelable";
        };
      };

      ${backendName} = {
        image = "ghcr.io/pouzor/homelable-backend:3.2.0";
        volumeMap.data = "${storage}/data:/app/data";

        extraEnv =
          {
            SECRET_KEY.fromFile = cfg.secretKeyFile;
            SQLITE_PATH = "/app/data/homelab.db";
            AUTH_MODE =
              if cfg.oidc.enable
              then "oidc"
              else "local";
            AUTH_USERNAME = cfg.auth.username;
          }
          // lib.optionalAttrs (cfg.auth.passwordHashFile != null) {
            AUTH_PASSWORD_HASH.fromFile = cfg.auth.passwordHashFile;
          }
          // lib.optionalAttrs (cfg.scannerRanges != []) {
            # Pass from file to avoid shell escaping issues with commas in CIDR ranges
            SCANNER_RANGES.fromFile = pkgs.writeText "scanner-ranges" (builtins.toJSON cfg.scannerRanges);
          }
          // lib.optionalAttrs cfg.oidc.enable {
            CORS_ORIGINS.fromFile = pkgs.writeText "cors-origins" (builtins.toJSON ["${cfg.containers.${name}.traefik.serviceUrl}"]);
            OIDC_DISCOVERY_URL = "${config.nps.containers.authelia.traefik.serviceUrl}/.well-known/openid-configuration";
            OIDC_CLIENT_ID = name;
            OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            OIDC_REDIRECT_URI = "${cfg.containers.${name}.traefik.serviceUrl}/api/v1/auth/oidc/callback";
            OIDC_SCOPES = "openid profile email";
            OIDC_COOKIE_SECURE = true;
            OIDC_SESSION_EXPIRE_MINUTES = 480;
            OIDC_TRANSACTION_EXPIRE_SECONDS = 600;
          }
          // lib.optionalAttrs cfg.mcp.enable {
            MCP_SERVICE_KEY.fromFile = cfg.mcp.serviceKeyFile;
          }
          // cfg.extraEnv;

        # Join Traefik network for internal communication required for OIDC
        network = [config.nps.stacks.traefik.network.name];

        # Required for ping-based status checks
        addCapabilities = ["NET_RAW"];

        # The frontend image expects the backend to be reachable as "backend"
        extraConfig.Container = {
          # Required for the frontend to reach the backend
          NetworkAlias = "backend";

          Notify = "healthy";
          HealthCmd = "curl -f http://localhost:8000/api/v1/health";
          HealthInterval = "10s";
          HealthTimeout = "5s";
          HealthRetries = 6;
          HealthStartPeriod = "15s";
          HealthOnFailure = "kill";
        };

        stack = name;
        glance = {
          inherit category;
          parent = name;
          name = "Backend";
          icon = "di:homelable";
        };
      };

      ${mcpName} = lib.mkIf cfg.mcp.enable {
        image = "ghcr.io/pouzor/homelable-mcp:3.2.0";

        extraEnv = {
          BACKEND_URL = "http://${backendName}:8000";
          MCP_API_KEY.fromFile = cfg.mcp.apiKeyFile;
          MCP_SERVICE_KEY.fromFile = cfg.mcp.serviceKeyFile;
        };

        wantsContainer = [backendName];
        stack = name;
        glance = {
          inherit category;
          parent = name;
          name = "MCP Server";
          icon = "di:homelable";
        };
      };
    };
  };
}
