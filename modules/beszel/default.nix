{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "beszel";
  agentName = "${name}-agent";

  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml {};

  socketTargetLocation = "/var/run/podman.sock";

  category = "Monitoring";
  displayName = "Beszel";
  description = "Lightweight Monitoring Platform";
in {
  imports =
    [
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {
        stack = name;
        container = agentName;
        targetLocation = socketTargetLocation;
      })
    ]
    ++ import ../mkAliases.nix config lib name [
      name
      agentName
    ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminProvisioning = {
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email address for the initial admin user";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to a file containing the initial admin user password.";
      };
    };
    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the Beszel token (UUIDv4). The token is used by the agent to self-register itself at the hub.
        Can be generated using `uuidgen`
      '';
    };
    ed25519PrivateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to private SSH key that will be used by the hub to authenticate against agent
      '';
    };
    ed25519PublicKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to public SSH key of the hub that will be considered authorized by agent
      '';
    };
    settings = lib.mkOption {
      type = lib.types.nullOr yaml.type;
      default = null;
      apply = settings:
        if (settings != null)
        then yaml.generate "config.yml" settings
        else null;
      description = ''
        System configuration (optional).
        If provided, on each restart, systems in the database will be updated to match the systems defined in the settings.
        To see your current configuration, refer to settings -> YAML Config -> Export configuration.

        The module will configure a single system called "Local" that connects to the Beszel hub through the beszel socket.

        The config will be templated using `gomplate`, so you can refer to secrets etc.
      '';
      example = {
        systems = [
          {
            name = "Some Remote System";
            host = "some.remote.host";
            token = ''{{ file.Read `''${config.sops.secrets."BESZEL_REMOTE_TOKEN".path}`}}'';
            users = ["admin@example.com"];
          }
        ];
      };
    };
    oidc = {
      registerClient = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to register a Beszel OIDC client in Authelia.
          If enabled you need to provide a hashed secret in the `client_secret` option.

          To enable OIDC Login for Beszel, you will have to set it up in Beszels Web-UI.
          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/beszel/>
          - <https://beszel.dev/guide/oauth>
        '';
      };
      clientSecretHash = (import ../authelia/options.nix lib).clientSecretHash;
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.registerClient {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.registerClient {
      oidc.clients.${name} = {
        client_name = "Beszel";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/oauth2-redirect"
        ];
      };
      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level
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

    nps.stacks.beszel.settings = {
      systems = [
        {
          name = "Local";
          host = "/beszel_socket/beszel.sock";
          token = "{{ file.Read `${cfg.tokenFile}`}}";
          users = [cfg.adminProvisioning.email];
        }
      ];
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/henrygd/beszel/beszel:0.19.0";
        volumeMap =
          {
            data = "${storage}/data:/beszel_data";
            socket = "${storage}/beszel_socket:/beszel_socket";
          }
          // lib.optionalAttrs (cfg.ed25519PrivateKeyFile != null) {privateKey = "${cfg.ed25519PrivateKeyFile}:/beszel_data/id_ed25519";}
          // lib.optionalAttrs (cfg.ed25519PublicKeyFile != null) {publicKey = "${cfg.ed25519PublicKeyFile}:/beszel_data/id_ed25519.pub";};

        templateMount = lib.optional (cfg.settings != null) {
          templatePath = cfg.settings;
          destPath = "/beszel_data/config.yml";
        };

        extraEnv = {
          # If Authelia is enabled, allow automatic user creation on OIDC login.
          USER_CREATION = cfg.oidc.registerClient;

          USER_EMAIL = cfg.adminProvisioning.email;
          USER_PASSWORD.fromFile = cfg.adminProvisioning.passwordFile;
        };

        port = 8090;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "beszel";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:beszel";
        };
      };

      ${agentName} = {
        image = "ghcr.io/henrygd/beszel/beszel-agent:0.19.0";
        volumeMap.socket = "${storage}/beszel_socket:/beszel_socket";

        # No way to connect to socket proxy through host network yet
        # Check traefik tcp router with socket activation eventually
        network =
          if (!cfg.useSocketProxy)
          then ["host"]
          else [config.nps.stacks.traefik.network.name];

        extraEnv = {
          KEY.fromFile = cfg.ed25519PublicKeyFile;
          LISTEN = "/beszel_socket/beszel.sock";
          TOKEN.fromFile = cfg.tokenFile;
          HUB_URL = cfg.containers.${name}.traefik.serviceUrl;
          DOCKER_HOST =
            if !cfg.useSocketProxy
            then "unix://${socketTargetLocation}"
            else config.nps.stacks.docker-socket-proxy.address;
        };
        glance = {
          inherit category;
          parent = name;
          name = "Beszel Agent";
          icon = "di:beszel";
        };
      };
    };
  };
}
