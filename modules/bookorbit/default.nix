{
  config,
  lib,
  ...
}: let
  name = "bookorbit";
  dbName = "${name}-db";
  kokoroName = "${name}-kokoro";

  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Media & Downloads";
  description = "Reading Space";
  displayName = "BookOrbit";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
    kokoroName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    libraryPath = lib.mkOption {
      type = lib.types.str;
      default = "${storage}/books";
      defaultText = lib.literalExpression ''"''${config.nps.storageBaseDir}/${name}/books"'';
      description = "Host directory where the book files are stored.";
    };
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret that signs the login tokens.
        Can be generated with `openssl rand -hex 32`.
      '';
    };
    podcastEncryptionKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the file containing the key that encrypts the podcast URLs.

        Generate an independent key with `openssl rand -hex 32` and keep it stable, otherwise
        previously issued podcast URLs become invalid.
      '';
    };
    setupBootstrapTokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the token for the initial setup wizard.
        Can be generated with `openssl rand -hex 16`.
      '';
    };

    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Database user name for BookOrbit.";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing the database password for BookOrbit.
          Can be generated with `openssl rand -hex 24`.
        '';
      };
    };
    tts = {
      enable = lib.mkEnableOption "Kokoro text-to-speech";
    };
    oidc = {
      registerClient = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to register a BookOrbit OIDC client in Authelia.
          If enabled you need to provide a hashed secret in the `clientSecretHash` option.

          To enable OIDC Login for BookOrbit, you will have to enable it in the Web UI.

          For details, see:

          - <https://bookorbit.app/oidc/>
        '';
      };
      clientSecretHash = (import ../authelia/options.nix lib).clientSecretHash;
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = ''
          Users of this group will be assigned admin rights.

          In order to take effect, you will have to enter the value `groups` in the Group Claim form field in the BookOrbit UI.
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = ''
          Users of this group will be able to log in.

          In order to take effect, you will have to enter the value `groups` in the Group Claim form field in the BookOrbit UI.
        '';
      };
    };

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://bookorbit.app/installation/#environment-variables>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.registerClient {
      ${cfg.oidc.adminGroup} = {};
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.registerClient {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/oauth2-callback"
          "bookorbit://oauth2-callback"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
      };

      # BookOrbit maps groups to permissions instead of roles, so restrict user access on Authelia level.
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
        image = "ghcr.io/bookorbit/bookorbit:3.2.0";
        volumeMap = {
          books = "${cfg.libraryPath}:/books";
          data = "${storage}/data:/data";
        };

        extraEnv =
          {
            APP_URL = cfg.containers.${name}.traefik.serviceUrl;
            LIBRARY_BROWSE_ROOT = lib.mkDefault "/books";
            POSTGRES_HOST = dbName;
            POSTGRES_PORT = 5432;
            POSTGRES_DB = name;
            POSTGRES_USER = cfg.db.username;
            POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
            JWT_SECRET.fromFile = cfg.jwtSecretFile;
            SETUP_BOOTSTRAP_TOKEN.fromFile = cfg.setupBootstrapTokenFile;
            PODCAST_ENCRYPTION_KEY = lib.mkIf (cfg.podcastEncryptionKeyFile != null) {fromFile = cfg.podcastEncryptionKeyFile;};
            PUID = config.nps.defaultUid;
            PGID = config.nps.defaultGid;
          }
          // cfg.extraEnv;

        wantsContainer =
          [dbName]
          ++ (lib.optional cfg.tts.enable kokoroName)
          ++ (lib.optional cfg.oidc.registerClient "authelia");

        stack = name;
        port = 3000;
        traefik.name = name;
        dashboard = {
          inherit category description;
          name = displayName;
          icon = "di:bookorbit";
        };
      };

      ${dbName} = {
        image = "docker.io/pgvector/pgvector:pg18";
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";

        extraEnv = {
          POSTGRES_DB = name;
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -d ${name} -U ${cfg.db.username}";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
          HealthOnFailure = "kill";
        };

        stack = name;
        dashboard = {
          inherit category;
          name = "Postgres";
          icon = "di:postgres";
          parent = name;
        };
      };

      ${kokoroName} = lib.mkIf cfg.tts.enable {
        image = "ghcr.io/remsky/kokoro-fastapi-cpu:v0.9.0";

        stack = name;
        dashboard = {
          inherit category;
          name = "Kokoro";
          icon = "di:headphones";
          parent = name;
        };
      };
    };
  };
}
