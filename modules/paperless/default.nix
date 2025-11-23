{
  config,
  lib,
  ...
}: let
  name = "paperless";
  dbName = "${name}-db";
  brokerName = "${name}-broker";
  ftpName = "${name}-ftp";

  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Document Management System";
  displayName = "Paperless-ngx";
in {
  imports = import ../mkAliases.nix config lib name [
    name
    dbName
    brokerName
    ftpName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the Paperless secret key

        See <https://docs.paperless-ngx.com/configuration/#PAPERLESS_SECRET_KEY>
      '';
    };
    adminProvisioning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to automatically create an admin user on the first run.
          If set to false, an admin user can be manually created using the `createsuperuser` command.

          See <https://docs.paperless-ngx.com/administration/#create-superuser>
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
    };

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://docs.paperless-ngx.com/configuration>
      '';
    };
    db = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "paperless";
        description = "Database user name for Paperless";
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the database password for Paperless";
      };
    };
    ftp = {
      enable = lib.mkEnableOption "FTP server";
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the FTP password";
      };
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration for Paperless.

          For details, see:

          For details, see:
          - <https://www.authelia.com/integration/openid-connect/clients/paperless/>
          - <https://docs.paperless-ngx.com/advanced_usage/#openid-connect-and-social-authentication>
        '';
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          The file containing the client secret for the Paperless OIDC client that will be registered in Authelia.
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
        image = "ghcr.io/paperless-ngx/paperless-ngx:2.20.0";
        dependsOnContainer = [
          dbName
          brokerName
        ];
        volumes = [
          "${storage}/data:/usr/src/paperless/data"
          "${storage}/media:/usr/src/paperless/media"
          "${storage}/export:/usr/src/paperless/export"
          "${storage}/consume:/usr/src/paperless/consume"
        ];
        environment = {
          PAPERLESS_REDIS = "redis://${brokerName}:6379";
          PAPERLESS_DBHOST = dbName;
          USERMAP_UID = config.nps.defaultUid;
          USERMAP_GID = config.nps.defaultGid;
          PAPERLESS_TIME_ZONE = config.nps.defaultTz;
          PAPERLESS_FILENAME_FORMAT = "{{created_year}}/{{correspondent}}/{{title}}";
          PAPERLESS_URL = config.services.podman.containers.${name}.traefik.serviceUrl;
        };

        extraEnv =
          {
            PAPERLESS_DBUSER = cfg.db.username;
            PAPERLESS_DBPASS.fromFile = cfg.db.passwordFile;
            PAPERLESS_SECRET_KEY.fromFile = cfg.secretKeyFile;
          }
          // lib.optionalAttrs cfg.adminProvisioning.enable {
            PAPERLESS_ADMIN_USER = cfg.adminProvisioning.username;
            PAPERLESS_ADMIN_MAIL = cfg.adminProvisioning.email;
            PAPERLESS_ADMIN_PASSWORD.fromFile = cfg.adminProvisioning.passwordFile;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
            PAPERLESS_SOCIALACCOUNT_PROVIDERS.fromTemplate = let
              autheliaUrl = config.nps.containers.authelia.traefik.serviceUrl;
            in
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
                        server_url = autheliaUrl;
                        token_auth_method = "client_secret_basic";
                      };
                    }
                  ];
                };
              }
              |> builtins.toJSON
              |> lib.replaceStrings ["\n"] [""];
          }
          // cfg.extraEnv;

        port = 8000;

        stack = name;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "paperless-ngx";
            widget.type = "paperlessngx";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:paperless-ngx";
        };
      };

      ${brokerName} = {
        image = "docker.io/redis:8.0";
        stack = name;
        glance = {
          parent = name;
          name = "Redis";
          icon = "di:redis";
          inherit category;
        };
      };

      ${dbName} = {
        image = "docker.io/postgres:16";
        volumes = ["${storage}/db:/var/lib/postgresql/data"];
        extraEnv = {
          POSTGRES_DB = "paperless";
          POSTGRES_USER = cfg.db.username;
          POSTGRES_PASSWORD.fromFile = cfg.db.passwordFile;
        };

        stack = name;
        glance = {
          parent = name;
          name = "Postgres";
          icon = "di:postgres";
          inherit category;
        };
      };

      ${ftpName} = let
        uid = config.nps.defaultUid;
        gid = config.nps.defaultGid;

        user =
          if uid == 0
          then "root"
          else "paperless";
        home =
          if uid == 0
          then "/${user}"
          else "home/${user}";
      in
        lib.mkIf cfg.ftp.enable {
          image = "docker.io/garethflowers/ftp-server:0.9.2";
          volumes = [
            "${storage}/consume:${home}"
          ];
          extraEnv = {
            PUBLIC_IP = config.nps.hostIP4Address;
            FTP_USER = user;
            FTP_PASS.fromFile = cfg.ftp.passwordFile;
            UID = uid;
            GID = gid;
          };

          ports = [
            "21:21"
            "40000-40009:40000-40009"
          ];

          glance = {
            parent = name;
            name = "FTP-Server";
            icon = "si:sftpgo";
            inherit category;
          };
        };
    };
  };
}
