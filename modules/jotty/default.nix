{
  config,
  lib,
  ...
}: let
  name = "jotty";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Checklists & Notes";
  displayName = "Jotty";
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

          For details, see:
          - <https://github.com/fccview/jotty/blob/main/howto/SSO.md>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = ''
          Users of this group will be admin
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = ''
          Users of this group will be able to log in
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
      ${cfg.oidc.adminGroup} = {};
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
          "${cfg.containers.${name}.traefik.serviceUrl}/api/oidc/callback"
        ];
        token_endpoint_auth_method = "client_secret_post";
        claims_policy = name;
      };

      # Jotty doesn't seem to fetch claims from userinfo endpoint
      settings.identity_providers.oidc.claims_policies.${name}.id_token = [
        "email"
        "email_verified"
        "preferred_username"
        "name"
      ];

      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level for now
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

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/fccview/jotty:1.19.0";

        volumes = [
          "${storage}/data:/app/data"
          "${storage}/config:/app/config"
          "${storage}/cache:/app/.next/cache"
        ];
        environment = {
          NODE_ENV = "production";
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
        };

        extraEnv = lib.mkIf cfg.oidc.enable {
          SSO_MODE = "oidc";
          OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
          OIDC_CLIENT_ID = name;
          APP_URL = cfg.containers.${name}.traefik.serviceUrl;
          OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          OIDC_ADMIN_GROUPS = cfg.oidc.adminGroup;
          OIDC_GROUPS_SCOPE = "groups";
        };

        stack = name;
        port = 3000;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "jotty";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:jotty";
        };
      };
    };
  };
}
