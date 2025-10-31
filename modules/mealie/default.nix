{
  config,
  lib,
  ...
}: let
  name = "mealie";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Recipe Manager";
  displayName = "Mealie";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/mealie/>
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
        default = "${name}_admin";
        description = "Users of this group will be assigned admin rights";
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users must be a part of this group to be able to log in.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.adminGroup} = {};
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Mealie";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/login"
        ];
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/mealie-recipes/mealie:v3.4.0";
        volumes = ["${storage}/data:/app/data/"];
        environment = {
          ALLOW_SIGNUP = false;
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          BASE_URL = config.services.podman.containers.${name}.traefik.serviceUrl;
          DB_ENGINE = "sqlite";
          #ALLOW_PASSWORD_LOGIN = false;
        };

        extraEnv = lib.optionalAttrs cfg.oidc.enable {
          OIDC_AUTH_ENABLED = true;
          OIDC_PROVIDER_NAME = "Authelia";
          OIDC_SIGNUP_ENABLED = true;
          OIDC_CONFIGURATION_URL = "${config.nps.containers.authelia.traefik.serviceUrl}/.well-known/openid-configuration";
          OIDC_CLIENT_ID = name;
          OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          OIDC_AUTO_REDIRECT = false;
          OIDC_ADMIN_GROUP = cfg.oidc.adminGroup;
          OIDC_USER_GROUP = cfg.oidc.userGroup;
        };

        port = 9000;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "mealie";
            widget.type = "mealie";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:mealie";
        };
      };
    };
  };
}
