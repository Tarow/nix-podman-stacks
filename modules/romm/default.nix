{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "romm";
  dbName = "${name}-db";

  storage = "${config.nps.storageBaseDir}/${name}";
  defaultRomStorage = "${storage}/library";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Rom Manager";
  displayName = "RomM";

  yaml = pkgs.formats.yaml {};
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminProvisioning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = !cfg.oidc.enable;
        description = ''
          Whether to automatically create an admin user on the first run.
          If set to false, you will be prompted to create an admin user when visiting the web ui.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username for the admin user";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email address for the admin user";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to a file containing the admin user password";
      };
    };
    authSecretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the random secret key.
        Can be generated with `openssl rand -hex 32`.
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
      type = yaml.type;
      apply = yaml.generate "config.yml";
      default = {};
      example = {
        platforms = {
          gc = "ngc";
          psx = "ps";
        };
      };
      description = ''
        RomM settings. Will be mounted as the `config.yml`.

        See <https://docs.romm.app/latest/Getting-Started/Configuration-File/>
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://docs.romm.app/latest/Getting-Started/Environment-Variables/>
      '';
      example = {
        IGDB_CLIENT_SECRET = {
          fromFile = "/run/secrets/igdb_client_secret";
        };
        UPLOAD_TIMEOUT = 900;
      };
    };

    oidc = {
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
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = "Users of this group will be able to log in";
      };
      editorGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_editor";
        description = "Users of this group will be assigned the 'editor' role";
      };
      viewerGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_viewer";
        description = "Users of this group will assigned the 'viewer' role";
      };
    };
    db = {
      userPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the romm database user";
      };
      rootPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the password for the MariaDB root user";
      };
    };
    igir = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to install a helper program `igir-romm-cleanup` that can organize your ROM collection.
          Will setup defaults for dat, input & output dirs based on the configured library location.

          Also adds parameters to copy remaining (undetected) ROMs as well as grouping multi-disk games.

          See
          - <https://docs.romm.app/4.0.0/Tools/Igir-Collection-Manager/>
          - <https://igir.io/>
        '';
      };
      package = lib.mkPackageOption pkgs "igir" {};
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.igir.enable) (pkgs.callPackage ./igir_romm_cleanup.nix {
      igirPackage = cfg.igir.package;
      datDir = "${cfg.romLibraryPath}/dats";
      inputDir = "${cfg.romLibraryPath}/roms-unverified";
      outputDir = "${cfg.romLibraryPath}/roms";
    });

    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.adminGroup} = {};
      ${cfg.oidc.editorGroup} = {};
      ${cfg.oidc.viewerGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Rom Manager";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/oauth/openid"
        ];
        claims_policy = name;
      };

      # See <https://www.authelia.com/integration/openid-connect/clients/romm/#configuration-escape-hatch>
      settings.identity_providers.oidc.claims_policies.${name}.id_token = [
        "email"
        "email_verified"
        "alt_emails"
        "preferred_username"
        "name"
        "groups"
      ];
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/rommapp/romm:4.4.1";
        volumes = [
          "${storage}/resources:/romm/resources"
          "${storage}/redis_data:/redis-data"
          "${cfg.romLibraryPath}:/romm/library"
          "${storage}/assets:/romm/assets"
          "${cfg.settings}:/romm/config/config.yml"
        ];

        extraEnv = let
          db = cfg.containers.${dbName}.environment;
        in
          {
            ROMM_AUTH_SECRET_KEY.fromFile = cfg.authSecretKeyFile;
            HASHEOUS_API_ENABLED = true;
            DB_HOST = dbName;
            DB_NAME = db.MARIADB_DATABASE;
            DB_USER = db.MARIADB_USER;
            DB_PASSWD.fromFile = cfg.db.userPasswordFile;
          }
          // lib.optionalAttrs cfg.adminProvisioning.enable {
            ADMIN_USERNAME = cfg.adminProvisioning.username;
            ADMIN_PASSWORD.fromFile = cfg.adminProvisioning.passwordFile;
            ADMIN_EMAIL = cfg.adminProvisioning.email;
          }
          // lib.optionalAttrs (cfg.oidc.enable) (
            let
              authelia = config.nps.stacks.authelia;
              oidcClient = authelia.oidc.clients.${name};
            in {
              OIDC_ENABLED = true;
              OIDC_PROVIDER = "authelia";
              OIDC_CLIENT_ID = oidcClient.client_id;
              OIDC_REDIRECT_URI = lib.elemAt oidcClient.redirect_uris 0;
              OIDC_SERVER_APPLICATION_URL = authelia.containers.authelia.traefik.serviceUrl;
              OIDC_CLAIM_ROLES = "groups";
              OIDC_ROLE_ADMIN = cfg.oidc.adminGroup;
              OIDC_ROLE_EDITOR = cfg.oidc.editorGroup;
              OIDC_ROLE_VIEWER = cfg.oidc.viewerGroup;
              DISABLE_SETUP_WIZARD = true;
            }
          )
          // cfg.extraEnv;
        fileEnvMount.OIDC_CLIENT_SECRET_FILE = lib.mkIf cfg.oidc.enable cfg.oidc.clientSecretFile;

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
            ExecStartPost = lib.optional cfg.adminProvisioning.enable (
              lib.getExe (
                pkgs.writeShellScriptBin "user_provision" ''
                  ${lib.getExe pkgs.podman} exec ${name} bash -c "$(${pkgs.coreutils}/bin/cat ${./create_admin_user.sh})"
                ''
              )
            );
          };
        };

        dependsOnContainer = [dbName];
        stack = name;

        port = 8080;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "romm";
            widget.type = "romm";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:romm";
        };
      };
      ${dbName} = {
        image = "docker.io/mariadb:11";
        volumes = ["${storage}/db:/var/lib/mysql"];
        extraEnv = {
          MARIADB_DATABASE = "romm";
          MARIADB_USER = "romm-user";
          MARIADB_ROOT_PASSWORD.fromFile = cfg.db.rootPasswordFile;
          MARIADB_PASSWORD.fromFile = cfg.db.userPasswordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "healthcheck.sh --connect --innodb_initialized";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "20s";
        };

        stack = name;
        glance = {
          parent = name;
          name = "MariaDB";
          icon = "si:mariadb";
          inherit category;
        };
      };
    };
  };
}
