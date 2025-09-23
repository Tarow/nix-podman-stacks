{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "storyteller";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Media & Downloads";
  description = "Immersive Reading Platform";
  displayName = "Storyteller";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key.

        See <https://storyteller-platform.gitlab.io/storyteller/docs/intro/getting-started#secrets>
      '';
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and insert the necessary configuration records into the database.

          For details, see:
          - <https://storyteller-platform.gitlab.io/storyteller/docs/administering#oauthoidc-configuration>
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
          The hashed client_secret.
          For examples on how to generate a client secret, see

          <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
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
    };
    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Storyteller";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/v2/auth/callback/authelia"
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

    services.podman.containers.${name} = {
      image = "registry.gitlab.com/storyteller-platform/storyteller:web-v2.2.2";
      volumes = ["${storage}:/data"];

      environment.AUTH_URL = lib.mkIf cfg.oidc.enable "${cfg.containers.${name}.traefik.serviceUrl}/api/v2/auth";

      fileEnvMount.STORYTELLER_SECRET_KEY_FILE = cfg.secretKeyFile;
      extraConfig.Service.ExecStartPost = lib.optional cfg.oidc.enable (
        lib.getExe (
          pkgs.writeShellApplication {
            name = "storyteller-oidc-init";
            runtimeInputs = with pkgs; [coreutils sqlite libossp_uuid];
            text = ''
              UUID=$(uuid)
              sqlite3 ${storage}/storyteller.db <<SQL
              INSERT INTO settings (uuid, name, value)
              VALUES (
                  COALESCE(
                      (SELECT uuid FROM settings WHERE name = 'authProviders'),
                      '$UUID'
                  ),
                  'authProviders',
                  '[{"kind":"custom","name":"Authelia","issuer":"${config.nps.containers.authelia.traefik.serviceUrl}","clientId":"storyteller","clientSecret":"$(< ${cfg.oidc.clientSecretFile})","type":"oidc"}]'
              )
              ON CONFLICT(uuid) DO UPDATE SET value = excluded.value;
              SQL
            '';
          }
        )
      );

      extraConfig.Container = {
        Notify = "healthy";
        HealthCmd = "curl -s -f http://localhost:8001/api || exit 1";
        HealthInterval = "10s";
        HealthTimeout = "10s";
        HealthRetries = 5;
        HealthStartPeriod = "5s";
      };

      port = 8001;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "sh-storyteller";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:sh-storyteller";
      };
    };
  };
}
