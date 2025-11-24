{
  config,
  lib,
  ...
}: let
  name = "tandoor";
  dbName = "${name}-db";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Recipe Manager";
  displayName = "Tandoor";
in {
  imports = import ../mkAliases.nix config lib name [name dbName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the Paperless secret key

        See <https://docs.tandoor.dev/system/configuration/#secret-key>
      '';
    };
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "tandoor";
        description = "Database user name";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the database password";
      };
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/tandoor/>
          - <https://docs.tandoor.dev/features/authentication/oidc/>
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
        description = "Users must be a part of this group to be able to log in.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Paperless";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/accounts/oidc/authelia/login/callback/"
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

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/tandoorrecipes/recipes:2.3.6";
        volumes = [
          "${storage}/staticfiles:/opt/recipes/staticfiles"
          "${storage}/mediafiles:/opt/recipes/mediafiles"
        ];

        extraEnv = let
          db = cfg.containers.${dbName}.extraEnv;
        in
          {
            SECRET_KEY.fromFile = cfg.secretKeyFile;
            ALLOWED_HOSYTS = cfg.containers.${name}.traefik.serviceHost;
            DB_ENGINE = "django.db.backends.postgresql";
            POSTGRES_HOST = dbName;
            POSTGRES_DB = db.POSTGRES_DB;
            POSTGRES_USER = db.POSTGRES_USER;
            POSTGRES_PASSWORD = db.POSTGRES_PASSWORD;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
            SOCIALACCOUNT_PROVIDERS.fromTemplate =
              {
                openid_connect = {
                  SCOPE = ["openid" "profile" "email"];
                  OAUTH_PKCE_ENABLED = true;
                  APPS = [
                    {
                      provider_id = "authelia";
                      name = "Authelia";
                      client_id = name;
                      secret = ''{{ file.Read `${cfg.oidc.clientSecretFile}` }}'';
                      settings = {
                        server_url = config.nps.containers.authelia.traefik.serviceUrl;
                        token_auth_method = "client_secret_basic";
                      };
                    }
                  ];
                };
              }
              |> builtins.toJSON
              |> lib.replaceStrings ["\n"] [""];
          };
        dependsOnContainer = [dbName];

        stack = name;
        port = 80;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "tandoor-recipes";
            widget.type = "tandoor";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:tandoor-recipes";
        };
      };

      ${dbName} = {
        image = "docker.io/postgres:18";
        volumes = ["${storage}/postgres:/var/lib/postgresql"];
        extraEnv = {
          POSTGRES_DB = "tandoor";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        stack = name;
        glance = {
          inherit category;
          name = "Postgres";
          parent = name;
          icon = "di:postgres";
        };
      };
    };
  };
}
