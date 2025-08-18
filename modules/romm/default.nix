{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  name = "romm";
  dbName = "${name}-db";

  storage = "${config.nps.storageBaseDir}/${name}";
  defaultRomStorage = "${storage}/library";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml { };
in
{
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    setupAdminUser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable automated admin user provisioning.
        If enabled, an admin user will be created automatically on startup.

        Make sure the file provided in the `envFile` option contains the variables `ADMIN_USERNAME` (default 'admin'),
        `ADMIN_PASSWORD` (default 'admin') and `ADMIN_EMAIL` (default 'admin@admin.com').

        When disabled, you will be prompted for admin user creation when visiting the RomM UI the first time.
      '';
    };
    romLibraryPath = lib.mkOption {
      type = lib.types.pathWith {
        inStore = false;
        absolute = true;
      };
      default = defaultRomStorage;
      defaultText = lib.literalExpression ''"''${config.nps.storageBaseDir}/${name}/library"'';
      example = lib.literalExpression ''"''${config.nps.externalStorageBaseDir}/${name}/library"'';
      description = ''
        Base path on the host where the rom library is stored.
      '';
    };
    settings = lib.mkOption {
      type = lib.types.nullOr yaml.type;
      default = null;
      apply = settings: if settings != null then yaml.generate "config.yml" settings else null;
      example = {
        platforms = {
          gc = "ngc";
          psx = "ps";
        };
      };
      description = ''
        RomM settings. If set, will be mounted as the `config.yml`.
        If unset, configuration through UI is possible.

        See <https://docs.romm.app/latest/Getting-Started/Configuration-File/>
      '';
    };
    env = lib.mkOption {
      type = (options.services.podman.containers.type.getSubOptions [ ]).environment.type;
      default = { };
      description = ''
        Additional environment variables passed to the RomM container

        See <https://docs.romm.app/latest/Getting-Started/Environment-Variables/>
      '';
    };
    envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to env file containing the `DB_PASSWD` and the `ROMM_AUTH_SECRET_KEY` variables.
        The `DB_PASSWD` should match the `MARIA_DB` password passed in the `db.envFile` option.

        Can optionally include more secrets and other variables, such as API_KEYS, e.g.
        `RETROACHIEVEMENTS_API_KEY` or `STEAMGRIDDB_API_KEY`.

        See <https://docs.romm.app/latest/Getting-Started/Environment-Variables/>
      '';
    };
    authelia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary environment variables in RomM.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/romm/>
          - <https://docs.romm.app/latest/OIDC-Guides/OIDC-Setup-With-Authelia/>
        '';
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing that client secret that will be used by RomM to authenticate against Authelia.
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
    };
    db.envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the env file containing the 'MARIADB_ROOT_PASSWORD' and 'MARIADB_PASSWORD' variables.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.authelia = lib.mkIf cfg.authelia.enable {
      oidc.clients.${name} = {
        client_name = "Rom Manager";
        client_secret = cfg.authelia.clientSecretHash;
        public = false;
        authorization_policy = "one_factor";
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = "1 month";
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceDomain}/api/oauth/openid"
        ];
        claims_policy = "romm";
      };

      # See <https://www.authelia.com/integration/openid-connect/clients/romm/#configuration-escape-hatch>
      settings.identity_providers.oidc.claims_policies.romm.id_token = [
        "email"
        "email_verified"
        "alt_emails"
        "preferred_username"
        "name"
      ];
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/rommapp/romm:4.1.3";
        volumes = [
          "${storage}/resources:/romm/resources"
          "${storage}/redis_data:/redis-data"
          "${cfg.romLibraryPath}:/romm/library"
          "${storage}/assets:/romm/assets"
        ]
        ++ [
          (
            if (cfg.settings == null) then
              "${storage}/config:/romm/config"
            else
              "${cfg.settings}:/romm/config/config.yml"
          )
        ];

        environmentFile = [ cfg.envFile ];
        environment =
          let
            db = cfg.containers.${dbName}.environment;
          in
          {
            DB_HOST = dbName;
            DB_NAME = db.MARIADB_DATABASE;
            DB_USER = db.MARIADB_USER;
          }
          // lib.optionalAttrs (cfg.authelia.enable) (
            let
              authelia = config.nps.stacks.authelia;
              oidcClient = authelia.oidc.clients.${name};
            in
            {
              OIDC_ENABLED = true;
              OIDC_PROVIDER = "authelia";
              OIDC_CLIENT_ID = oidcClient.client_id;
              OIDC_REDIRECT_URI = lib.elemAt oidcClient.redirect_uris 0;
              OIDC_SERVER_APPLICATION_URL = authelia.containers.authelia.traefik.serviceDomain;
            }
          )
          // cfg.env;
        fileEnvMount.OIDC_CLIENT_SECRET_FILE = lib.mkIf cfg.authelia.enable cfg.authelia.clientSecretFile;

        extraConfig = {
          Container = {
            Notify = "healthy";
            HealthCmd = "curl -s -f http://localhost:8080/api/heartbeat || exit 1";
            HealthInterval = "10s";
            HealthTimeout = "10s";
            HealthRetries = 5;
            HealthStartPeriod = "5s";
          };
          Service = {
            ExecStartPost = lib.mkIf cfg.setupAdminUser (
              lib.getExe (
                pkgs.writeShellScriptBin "user_provision" ''
                  ${lib.getExe pkgs.podman} exec ${name} bash -c "$(${pkgs.coreutils}/bin/cat ${./create_admin_user.sh})"
                ''
              )
            );
          };
        };

        dependsOnContainer = [ dbName ];
        stack = name;

        port = 8080;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "RomM";
          settings = {
            description = "Rom Manager";
            icon = "romm";
            widget.type = "romm";
          };
        };
      };
      ${dbName} = {
        image = "docker.io/mariadb:11";
        volumes = [ "${storage}/db:/var/lib/mysql" ];
        environment = {
          MARIADB_DATABASE = "romm";
          MARIADB_USER = "romm-user";
        };
        environmentFile = [ cfg.db.envFile ];

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "healthcheck.sh --connect --innodb_initialized";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "20s";
        };

        stack = name;
      };
    };
  };
}
