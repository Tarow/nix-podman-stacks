{
  config,
  lib,
  ...
}: let
  name = "stirling-pdf";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Web-based PDF-Tools";
  displayName = "Stirling PDF";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          !Important!
          For SSO to work, you will need a valid license for Stirling PDF that includes OAuth2 / OIDC support.

          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/stirling-pdf/>
          - <https://docs.stirlingpdf.com/Configuration/OAuth%20SSO%20Configuration>
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
          "${cfg.containers.${name}.traefik.serviceUrl}/login/oauth2/code/Authelia"
        ];
      };

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
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
      image = "docker.io/stirlingtools/stirling-pdf:2.4.2";
      volumes = [
        "${storage}/configs:/configs"
      ];
      extraEnv =
        {
          DOCKER_ENABLE_SECURITY = false;
          SECURITY_ENABLELOGIN = false;
          ALLOW_GOOGLE_VISIBILITY = false;
          SYSTEM_ENABLEANALYTICS = false;
          SYSTEM_ROOTURIPATH = "/";
        }
        // lib.optionalAttrs cfg.oidc.enable {
          DOCKER_ENABLE_SECURITY = true;
          SECURITY_ENABLE_LOGIN = true;
          SECURITY_LOGINMETHOD = "oauth2";
          SECURITY_OAUTH2_ENABLED = true;
          SECURITY_OAUTH2_AUTOCREATEUSER = true;
          SECURITY_OAUTH2_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
          SECURITY_OAUTH2_CLIENTID = name;
          SECURITY_OAUTH2_CLIENTSECRET.fromFile = cfg.oidc.clientSecretFile;
          SECURITY_OAUTH2_BLOCKREGISTRATION = false;
          SECURITY_OAUTH2_SCOPES = "openid,profile";
          SECURITY_OAUTH2_USEASUSERNAME = "preferred_username";
          SECURITY_OAUTH2_PROVIDER = "Authelia";
        };

      port = 8080;
      traefik.name = "pdf";
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "stirling-pdf";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:stirling-pdf";
      };
    };
  };
}
