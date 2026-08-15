{
  config,
  lib,
  ...
}: let
  name = "wallos";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Subscription Tracker";
  displayName = "Wallos";
in {
  imports = import ../mkAliases.nix config lib name [
    name
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          To enable OIDC Login, you will have to set it up in Web-UI.
          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/wallos/>
          - <https://github.com/ellite/Wallos?tab=readme-ov-file#oidc>
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
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/index.php"
        ];
        token_endpoint_auth_method = "client_secret_post";
      };

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
        image = "docker.io/bellamy/wallos:5.4.4";

        volumeMap = {
          db = "${storage}/db:/var/www/html/db";
          logos = "${storage}/logos:/var/www/html/images/uploads/logos";
        };

        extraEnv = lib.optionalAttrs cfg.oidc.enable {
          OIDC_ENABLED = true;
          OIDC_PROVIDER_NAME = "Authelia";
          OIDC_CLIENT_ID = name;
          OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
          OIDC_REDIRECT_URL = "${cfg.containers.${name}.traefik.serviceUrl}/index.php";
          OIDC_USER_IDENTIFIER = "sub";
          OIDC_SCOPES = "openid profile email";
          OIDC_AUTO_CREATE_USER = lib.mkDefault true;
          OIDC_DISABLE_PASSWORD_LOGIN = lib.mkDefault true;
          SSRF_ALLOWLIST = config.nps.containers.authelia.traefik.serviceHost;
        };

        stack = name;
        port = 80;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "wallos";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:wallos.webp";
        };
      };
    };
  };
}
