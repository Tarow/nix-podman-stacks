{
  config,
  lib,
  ...
}: let
  name = "karakeep";
  chromeName = "${name}-chrome";
  meilisearchName = "${name}-meilisearch";

  storage = "${config.nps.storageBaseDir}/${name}";

  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Bookmark Everything";
  displayName = "Karakeep";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    chromeName
    meilisearchName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    nextauthSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to file containing the NEXTAUTH_SECRET

        See <https://docs.karakeep.app/configuration/>
      '';
    };
    meiliMasterKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to file containing the MEILI_MASTER_KEY

        See <https://docs.karakeep.app/configuration/>
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

          - <https://www.authelia.com/integration/openid-connect/clients/karakeep/>
          - <https://docs.karakeep.app/configuration/#authentication--signup>
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
        client_name = "Karakeep";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        claims_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/callback/custom"
        ];
      };

      # See <https://www.authelia.com/integration/openid-connect/openid-connect-1.0-claims/#restore-functionality-prior-to-claims-parameter>
      settings.identity_providers.oidc.claims_policies.${name}.id_token = [
        "email"
        "email_verified"
        "alt_emails"
        "preferred_username"
        "name"
      ];

      # Karakeep doesn't have any Group/Claim based RBAC yet, so we have to do in on Authelia level
      # See <https://github.com/karakeep-app/karakeep/issues/1525>
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
        image = "ghcr.io/karakeep-app/karakeep:0.28.0";
        volumes = [
          "${storage}/data:/data"
        ];
        environment = {
          DATA_DIR = "/data";
          MEILI_ADDR = "http://${meilisearchName}:7700";
          BROWSER_WEB_URL = "http://${chromeName}:9222";
          NEXTAUTH_URL = cfg.containers.${name}.traefik.serviceUrl;
        };
        extraEnv =
          {
            NEXTAUTH_SECRET.fromFile = cfg.nextauthSecretFile;
            MEILI_MASTER_KEY.fromFile = cfg.meiliMasterKeyFile;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            OAUTH_WELLKNOWN_URL = "${config.nps.containers.authelia.traefik.serviceUrl}/.well-known/openid-configuration";
            OAUTH_CLIENT_ID = name;
            OAUTH_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            OAUTH_PROVIDER_NAME = "Authelia";
          };

        stack = name;
        port = 3000;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "karakeep";
            widget.type = "karakeep";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "auto-invert di:karakeep-dark";
        };
      };

      ${chromeName} = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        exec = lib.concatStringsSep " " [
          "--no-sandbox"
          "--disable-gpu"
          "--disable-dev-shm-usage"
          "--remote-debugging-address=0.0.0.0"
          "--remote-debugging-port=9222"
          "--hide-scrollbars"
        ];

        stack = name;
        glance = {
          inherit category;
          name = "Chrome";
          parent = name;
          icon = "di:chrome";
        };
      };

      ${meilisearchName} = {
        image = "docker.io/getmeili/meilisearch:v1.15.2";
        environment = {
          MEILI_NO_ANALYTICS = "true";
        };
        extraEnv = {
          MEILI_MASTER_KEY.fromFile = cfg.meiliMasterKeyFile;
        };
        volumes = ["${storage}/meilisearch:/meili_data"];

        stack = name;
        glance = {
          inherit category;
          name = "Meilisearch";
          parent = name;
          icon = "di:meilisearch";
        };
      };
    };
  };
}
