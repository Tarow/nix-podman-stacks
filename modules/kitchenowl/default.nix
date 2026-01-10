{
  config,
  lib,
  ...
}: let
  stackName = "kitchenowl";
  frontendName = "${stackName}-web";
  backendName = "${stackName}-backend";

  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";

  category = "General";
  description = "Grocery List & Recipe Manager";
  displayName = "KitchwenOwl";
in {
  imports = import ../mkAliases.nix config lib stackName [
    frontendName
    backendName
  ];

  options.nps.stacks.${stackName} = {
    enable = lib.mkEnableOption stackName;
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the JWT secret.
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

          - <https://www.authelia.com/integration/openid-connect/clients/kitchenowl/>
          - <https://docs.kitchenowl.org/latest/self-hosting/oidc/>
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
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${frontendName}.traefik.serviceUrl}/signin/redirect"
          "kitchenowl:/signin/redirect"
        ];
        claims_policy = stackName;
        token_endpoint_auth_method = "client_secret_post";
      };

      settings.identity_providers.oidc.claims_policies.${stackName}.id_token = [
        "email"
        "email_verified"
        "alt_emails"
        "preferred_username"
        "name"
      ];

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
      settings.identity_providers.oidc.authorization_policies.${stackName} = {
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
      ${frontendName} = {
        image = "docker.io/tombursch/kitchenowl-web:v0.7.5";
        environment.BACK_URL = "${backendName}:5000";

        stack = stackName;
        port = 80;
        traefik.name = stackName;
        dependsOnContainer = [backendName];

        glance = {
          inherit category description;
          name = displayName;
          parent = stackName;
          icon = "di:kitchenowl";
        };
      };

      ${backendName} = {
        image = "docker.io/tombursch/kitchenowl-backend:v0.7.5";
        volumes = [
          "${storage}/data:/data"
        ];
        extraEnv =
          {
            JWT_SECRET_KEY.fromFile = cfg.jwtSecretFile;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            FRONT_URL = "${cfg.containers.${frontendName}.traefik.serviceUrl}";
            OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
            OIDC_CLIENT_ID = stackName;
            OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          };

        stack = stackName;

        # Join Traefik network for internal communication required for OIDC
        network = [config.nps.stacks.traefik.network.name];

        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            href = cfg.containers.${frontendName}.traefik.serviceUrl;
            icon = "kitchenowl";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          url = cfg.containers.${frontendName}.traefik.serviceUrl;
          id = stackName;
          icon = "di:kitchenowl";
        };
      };
    };
  };
}
