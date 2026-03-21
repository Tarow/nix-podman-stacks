{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "forgejo";
  dbName = "${name}-db";

  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  ini = pkgs.formats.ini {};

  sshHostPort = "2222";

  category = "General";
  displayName = "Forgejo";
  description = "Git Server";

  runUser = cfg.settings.DEFAULT.RUN_USER or "git";

  adminProvisionScript = pkgs.writeShellApplication {
    name = "forgejo-admin-user-create";
    runtimeInputs = [config.nps.package pkgs.coreutils];
    bashOptions = [
      "errexit"
      "nounset"
      "pipefail"
    ];
    text = ''
      ${lib.concatStringsSep
        " "
        [
          "podman exec -u ${runUser}"
          "forgejo forgejo -c /data/gitea/conf/app.ini admin user create"
          "--username ${cfg.adminProvisioning.username}"
          "--email ${cfg.adminProvisioning.email}"
          "--password \"$(cat ${cfg.adminProvisioning.passwordFile})\""
          "--admin"
          "|| exit 0"
        ]}
    '';
  };

  oidcProviderName = "Authelia";
  oidcArgs = lib.concatStringsSep " " [
    ''--name "${oidcProviderName}"''
    ''--provider "openidConnect"''
    ''--key "${name}"''
    ''--secret "$(cat ${cfg.oidc.clientSecretFile})"''
    ''--auto-discover-url "${config.nps.containers.authelia.traefik.serviceUrl}/.well-known/openid-configuration" ''
    ''${lib.concatMapStringsSep " " (scope: "--scopes ${scope}") ["openid" "email" "profile" "groups"]} ''
    ''--group-claim-name "groups"''
    ''--admin-group "${cfg.oidc.adminGroup}"''
  ];

  setupOidcScript = pkgs.writeShellApplication {
    name = "forgejo-setup-oidc";
    runtimeInputs = with pkgs; [
      config.nps.package
      gawk
      gnugrep
      coreutils
    ];
    bashOptions = [
      "errexit"
      "nounset"
      "pipefail"
    ];
    text = ''
      CONTAINER_NAME="${name}"
      CONFIG_PATH="/data/gitea/conf/app.ini"
      PROVIDER_NAME="${oidcProviderName}"

      # Check if OIDC provider already exists
      AUTH_LIST=$(podman exec -u ${runUser} "$CONTAINER_NAME" forgejo --config "$CONFIG_PATH" admin auth list)

      # Extract ID if provider exists
      PROVIDER_ID=$(echo "$AUTH_LIST" | grep -E "^\s*[0-9]+\s+$PROVIDER_NAME\s+" | awk '{print $1}' || true)

      if [ -n "$PROVIDER_ID" ]; then
        echo "Found existing OIDC provider with ID: $PROVIDER_ID"
        echo "Updating OIDC configuration..."
        podman exec -u ${runUser} "$CONTAINER_NAME" \
          forgejo --config "$CONFIG_PATH" admin auth update-oauth --id "$PROVIDER_ID" ${oidcArgs}
        echo "OIDC provider updated successfully (ID: $PROVIDER_ID)"
      else
        echo "OIDC provider not found. Creating new provider..."

        podman exec -u ${runUser} "$CONTAINER_NAME" \
          forgejo --config "$CONFIG_PATH" admin auth add-oauth ${oidcArgs}
        echo "OIDC provider created successfully"
      fi
    '';
  };

  teardownOidcScript = pkgs.writeShellApplication {
    name = "forgejo-teardown-oidc";
    runtimeInputs = with pkgs; [
      config.nps.package
      gawk
      gnugrep
      coreutils
    ];
    bashOptions = [
      "errexit"
      "nounset"
      "pipefail"
    ];
    text = ''
      CONTAINER_NAME="${name}"
      CONFIG_PATH="/data/gitea/conf/app.ini"
      PROVIDER_NAME="${oidcProviderName}"

      # Check if OIDC provider already exists
      AUTH_LIST=$(podman exec -u ${runUser} "$CONTAINER_NAME" forgejo --config "$CONFIG_PATH" admin auth list)

      # Extract ID if provider exists
      PROVIDER_ID=$(echo "$AUTH_LIST" | grep -E "^\s*[0-9]+\s+$PROVIDER_NAME\s+" | awk '{print $1}' || true)

      if [ -n "$PROVIDER_ID" ]; then
        echo "Removing existing OIDC provider with ID: $PROVIDER_ID"
        podman exec -u ${runUser} "$CONTAINER_NAME" \
          forgejo --config "$CONFIG_PATH" admin auth delete --id "$PROVIDER_ID"
        echo "OIDC provider deleted successfully (ID: $PROVIDER_ID)"
      fi
    '';
  };
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    lfsJwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the LFS JWT secret.
        Can be generated using `forgejo generate secret LFS_JWT_SECRET`.

        See <https://forgejo.org/docs/next/admin/config-cheat-sheet/#server-server>
      '';
    };
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the global secret key.
        Can be generated using `forgejo generate secret SECRET_KEY`.

        See <https://forgejo.org/docs/latest/admin/config-cheat-sheet/#security-security>
      '';
    };
    internalTokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the internal token.
        Can be generated using `forgejo generate secret INTERNAL_TOKEN`.

        See <https://forgejo.org/docs/latest/admin/config-cheat-sheet/#security-security>
      '';
    };
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the OAuth2 jwt secret. This is needed, even if OAuth2 is not used.
        See <https://codeberg.org/forgejo/forgejo/issues/4570> for more information.

        Can be generated using `forgejo generate secret JWT_SECRET`.

        See <https://forgejo.org/docs/latest/admin/config-cheat-sheet/#oauth2-oauth2>
      '';
    };
    adminProvisioning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to automatically create an admin user on the first run.
          If set to false, an admin user can be manually created using the `forgejo` cli.

          See <https://forgejo.org/docs/next/admin/command-line/#admin-user-create>
        '';
      };
      username = lib.mkOption {
        type = lib.types.addCheck lib.types.str (s: s != "admin");
        default = "forgejo";
        description = "Username for the admin user. Cannot be `admin` as that name is reserved.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email address for the admin user ";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin password";
      };
    };
    settings = lib.mkOption {
      type = lib.types.nullOr ini.type;
      default = null;
      apply = settings:
        if (settings != null)
        then ini.generate "app.ini" settings
        else null;
      description = ''
        Additional app settings for Forgejo.
        For a full list of options, refer to the [Forgejo documentation](https://forgejo.org/docs/latest/admin/config-cheat-sheet/).
      '';
    };
    ssh.proxied = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to proxy SSH connections through Traefik. This will setup a TCP router in Traefik which forwards all traffic to the Forgejo container.
      '';
    };
    db = {
      type = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
        default = "sqlite";
        description = ''
          Type of the database to use.
          Can be set to "sqlite" or "postgres".
          If set to "postgres", the `passwordFile` option must be set.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "foregejo";
        description = ''
          The PostgreSQL user to use for the database.
          Only used if db.type is set to "postgres".
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the PostgreSQL password for the database.
          Only used if db.type is set to "postgres".
        '';
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
          "${cfg.containers.${name}.traefik.serviceUrl}/user/oauth2/${oidcProviderName}/callback"
        ];
      };

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

    nps.stacks.traefik = let
      sshName = "${name}-ssh";
    in
      lib.mkIf cfg.ssh.proxied {
        containers.traefik.ports = lib.mkAfter ["${sshHostPort}:${sshHostPort}"];
        staticConfig.entrypoints.${sshName}.address = ":${sshHostPort}";
        dynamicConfig.tcp = {
          routers.${sshName} = {
            entryPoints = [sshName];
            rule = "HostSNI(`*`)";
            service = sshName;
          };
          services."${sshName}".loadbalancer.servers = [
            {address = "${name}:22";}
          ];
        };
      };

    nps.stacks.${name}.settings = lib.mkMerge [
      (import ./settings.nix config)
      {
        server.FS_JWT_SECRET = "{{ file.Read `${cfg.lfsJwtSecretFile}` }}";
        security.SECRET_KEY = "{{ file.Read `${cfg.secretKeyFile}` }}";
        security.INTERNAL_TOKEN = "{{ file.Read `${cfg.internalTokenFile}` }}";
        oauth2.JWT_SECRET = "{{ file.Read `${cfg.jwtSecretFile}` }}";
      }
      (lib.mkIf (cfg.db.type == "sqlite") {
        database = {
          PATH = "/data/gitea/gitea.db";
          DB_TYPE = "sqlite3";
        };
      })
      (lib.mkIf (cfg.db.type == "postgres") {
        database = {
          DB_TYPE = "postgres";
          HOST = "${dbName}:5432";
          NAME = "forgejo";
          USER = cfg.db.username;
          PASSWD = "{{ file.Read `${cfg.db.passwordFile}` }}";
        };
      })
      (lib.mkIf cfg.oidc.enable {
        openid = {
          ENABLE_OPENID_SIGNIN = true;
          ENABLE_OPENID_SIGNUP = true;
          WHITELISTED_URIS = config.nps.containers.authelia.traefik.serviceHost;
        };
        service = {
          DISABLE_REGISTRATION = lib.mkDefault false;
          ALLOW_ONLY_EXTERNAL_REGISTRATION = lib.mkDefault true;
        };
      })
    ];

    services.podman.containers = {
      ${name} = {
        image = "codeberg.org/forgejo/forgejo:14";
        volumeMap.data = "${storage}/data:/data";
        ports = lib.mkIf (!cfg.ssh.proxied) ["${sshHostPort}:22"];

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "curl -s -f http://localhost:3000 || exit 1";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "5s";
          HealthOnFailure = "kill";
        };
        extraConfig.Service.ExecStartPost =
          lib.optional cfg.adminProvisioning.enable (lib.getExe adminProvisionScript)
          ++ [
            (
              if cfg.oidc.enable
              then (lib.getExe setupOidcScript)
              else (lib.getExe teardownOidcScript)
            )
          ];
        # Use template mount instead of "_URI" settings, as app.ini has to be writable anyways
        templateMount = lib.optional (cfg.settings != null) {
          templatePath = cfg.settings;
          destPath = "/data/gitea/conf/app.ini";
          chown = {
            user = "1000";
            group = "1000";
          };
        };

        stack = name;
        port = 3000;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "forgejo";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:forgejo";
        };
      };

      ${dbName} = lib.mkIf (cfg.db.type == "postgres") {
        image = "docker.io/postgres:18";
        volumeMap.data = "${storage}/postgres:/var/lib/postgresql";
        extraEnv = {
          POSTGRES_DB = "forgejo";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "pg_isready -d forgejo -U ${cfg.db.username}";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
          HealthOnFailure = "kill";
        };

        stack = name;
        glance = {
          parent = name;
          name = "Postgres";
          icon = "di:postgres";
          inherit category;
        };
      };
    };
  };
}
