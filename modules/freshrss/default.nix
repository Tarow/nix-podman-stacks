{
  config,
  lib,
  ...
}: let
  name = "freshrss";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Feeds Aggregator";
  displayName = "FreshRSS";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminProvisioning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to automatically create an admin user on the first run.
          If set to false, you will be prompted to create an admin user when visiting the FreshRSS web interface for the first time.
          This only affects the first run of the container.

          If you want to use OIDC login, disable this option. The first logged in OIDC user will be admin in that case.
          See <https://freshrss.github.io/FreshRSS/en/admins/16_OpenID-Connect.html>
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username for the admin user";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email address for the admin user ";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin user password";
      };
      apiPasswordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin API password";
      };
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          The first user created with OIDC login on initial setup will be admin.
          Make sure to follow the 'Initial Setup Process' instructions at <https://freshrss.github.io/FreshRSS/en/admins/16_OpenID-Connect.html>

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/freshrss/>
          - <https://freshrss.github.io/FreshRSS/en/admins/16_OpenID-Connect.html>
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
      cryptoKeyFile = lib.mkOption {
        type = lib.types.str;
        description = "Opaque key used for internal encryption.";
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
        client_name = "FreshRSS";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}:443/i/oidc/"
        ];
      };

      # FreshRSS doesn't seem to support blocking access to users that aren't part of a group, so we do it on Authelia level
      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = [
              "group:${cfg.oidc.userGroup}"
            ];
          }
        ];
      };
    };

    services.podman.containers.${name} = {
      image = "docker.io/freshrss/freshrss:1.27.1";
      volumes = [
        "${storage}/data:/var/www/FreshRSS/data"
        "${storage}/extensions:/var/www/FreshRSS/extensions"
      ];

      extraEnv =
        {
          CRON_MIN = "3,33";
          TRUSTED_PROXY = config.nps.stacks.traefik.network.subnet;
        }
        // lib.optionalAttrs (cfg.adminProvisioning.enable) {
          ADMIN_USERNAME = cfg.adminProvisioning.username;
          ADMIN_EMAIL = cfg.adminProvisioning.email;
          ADMIN_PASSWORD.fromFile = cfg.adminProvisioning.passwordFile;
          ADMIN_API_PASSWORD.fromFile = cfg.adminProvisioning.apiPasswordFile;

          FRESHRSS_INSTALL = "'${
            lib.concatStringsSep " " [
              "--api-enabled"
              "--base-url ${cfg.containers.${name}.traefik.serviceUrl}"
              "--default-user \\$\\$\{ADMIN_USERNAME\}"
              "--language en"
            ]
          }'";

          FRESHRSS_USER = "'${
            lib.concatStringsSep " " [
              "--api-password \\$\\$\{ADMIN_API_PASSWORD\}"
              "--email \\$\\$\{ADMIN_EMAIL\}"
              "--language en"
              "--password \\$\\$\{ADMIN_PASSWORD\}"
              "--user \\$\\$\{ADMIN_USERNAME\}"
            ]
          }'";
        }
        // lib.optionalAttrs cfg.oidc.enable {
          OIDC_ENABLED = 1;
          OIDC_PROVIDER_METADATA_URL = "${config.nps.containers.authelia.traefik.serviceUrl}/.well-known/openid-configuration";
          OIDC_CLIENT_ID = name;
          OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          OIDC_CLIENT_CRYPTO_KEY = cfg.oidc.cryptoKeyFile;
          OIDC_REMOTE_USER_CLAIM = "preferred_username";
          OIDC_SCOPES = ''\"openid groups email profile\"'';
          OIDC_X_FORWARDED_HEADERS = ''\"X-Forwarded-Host X-Forwarded-Port X-Forwarded-Proto\"'';
        };

      port = 80;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "freshrss";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:freshrss";
      };
    };
  };
}
