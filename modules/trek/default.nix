{
  config,
  lib,
  ...
}: let
  name = "trek";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  displayName = "Trek";
  description = "Collaborative Travel Planner";
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

          - <https://github.com/mauriceboe/TREK>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = "Users of this group will be assigned admin rights";
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
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
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/oidc/callback"
        ];
        token_endpoint_auth_method = "client_secret_post";
      };

      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = [
              "group:${cfg.oidc.adminGroup}"
              "group:${cfg.oidc.userGroup}"
            ];
          }
        ];
      };
    };

    services.podman.containers.${name} = {
      image = "docker.io/mauriceboe/trek:2.8.0";
      volumeMap = {
        data = "${storage}/data:/app/data";
        uploads = "${storage}/uploads:/app/uploads";
      };
      extraEnv =
        {
          PORT = 3000;
          NODE_ENV = "production";
        }
        // lib.optionalAttrs cfg.oidc.enable {
          OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
          OIDC_CLIENT_ID = name;
          OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          OIDC_DISPLAY_NAME = "Authelia";
          OIDC_ONLY = lib.mkDefault true;
          OIDC_ADMIN_CLAIM = "groups";
          OIDC_ADMIN_VALUE = cfg.oidc.adminGroup;
        };

      port = 3000;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "sh-trek";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "sh:trek";
      };
    };
  };
}
