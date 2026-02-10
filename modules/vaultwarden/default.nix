{
  config,
  lib,
  ...
}: let
  name = "vaultwarden";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Password Vault";
  displayName = "Vaultwarden";
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

          - <https://www.authelia.com/integration/openid-connect/clients/vaultwarden/>
          - <https://github.com/dani-garcia/vaultwarden/wiki/Enabling-SSO-support-using-OpenId-Connect>
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
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/dani-garcia/vaultwarden/blob/main/.env.template>
      '';
      example = {
        ADMIN_TOKEN = {
          fromFile = "/run/secrets/vaultwarden_admin_token";
        };
        ADMIN_SESSION_LIFETIME = 30;
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
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/identity/connect/oidc-signin"
        ];
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

    services.podman.containers.${name} = {
      image = "ghcr.io/dani-garcia/vaultwarden:1.35.3";
      volumeMap.data = "${storage}/data:/data";

      extraEnv =
        {
          DOMAIN = cfg.containers.${name}.traefik.serviceUrl;
        }
        // lib.optionalAttrs (cfg.oidc.enable) {
          SSO_ENABLED = true;
          SSO_SIGNUPS_MATCH_EMAIL = true;
          SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION = false;
          SSO_AUTHORITY = config.nps.containers.authelia.traefik.serviceUrl;
          SSO_PKCE = true;
          SSO_CLIENT_ID = name;
          SSO_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
        }
        // cfg.extraEnv;

      port = 80;
      traefik.name = "vw";
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "vaultwarden";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:vaultwarden";
      };
    };
  };
}
