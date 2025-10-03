{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "donetick";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
  yaml = pkgs.formats.yaml {};

  category = "General";
  displayName = "Donetick";
  description = "Task Organizer";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the JWT secret.
      '';
    };
    settings = lib.mkOption {
      type = yaml.type;
      default = {};
      description = ''
        Additional donetick settings. Will be provided as the `selhosted.yaml` file.

        See <https://github.com/donetick/donetick/blob/main/config/selfhosted.yaml>
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

          - <https://www.authelia.com/integration/openid-connect/clients/donetick/>
          - <https://docs.donetick.com/advance-settings/openid-connect-setup/>
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
        client_name = "Donetick";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/auth/oauth2"
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

    nps.stacks.${name}.settings = lib.mkMerge [
      {
        name = "selfhosted";
        is_done_tick_dot_com = false;
        is_user_creation_disabled = lib.mkDefault false;

        database = {
          type = "sqlite";
          migration = true;
        };

        jwt = {
          secret = "";
          session_time = "168h";
          max_refresh = "168h";
        };

        server = {
          port = 2021;
          read_timeout = "10s";
          write_timeout = "10s";
          rate_period = "60s";
          rate_limit = 300;
          cors_allow_origins = [
            cfg.containers.${name}.traefik.serviceUrl
            # the below are required for the android app to work
            "https://localhost"
            "capacitor://localhost"
          ];
          serve_frontend = true;
        };

        logging = {
          level = "info";
          encoding = "json";
          development = false;
        };

        scheduler_jobs = {
          due_job = "30m";
          overdue_job = "3h";
          pre_due_job = "3h";
        };

        realtime = {
          enabled = true;
          sse_enabled = true;
          heartbeat_interval = "60s";
          connection_timeout = "120s";
          max_connections = 1000;
          max_connections_per_user = 5;
          event_queue_size = 2048;
          cleanup_interval = "2m";
          stale_threshold = "5m";
          enable_compression = true;
          enable_stats = true;
          allowed_origins = ["*"];
        };
      }

      (lib.mkIf cfg.oidc.enable {
        oauth2 = let
          autheliaUrl = config.nps.containers.authelia.traefik.serviceUrl;
        in {
          name = "Authelia";
          client_id = name;
          client_secret = "";
          auth_url = "${autheliaUrl}/api/oidc/authorization";
          token_url = "${autheliaUrl}/api/oidc/token";
          user_info_url = "${autheliaUrl}/api/oidc/userinfo";
          redirect_url = "${cfg.containers.${name}.traefik.serviceUrl}/auth/oauth2";
          scopes = ["openid" "profile" "email"];
        };
      })
    ];

    services.podman.containers = {
      ${name} = {
        image = "docker.io/donetick/donetick:v0.1.64";
        volumes = [
          "${storage}/db:/donetick-data/"
          "${yaml.generate "selfhosted.yaml" cfg.settings}:/config/selfhosted.yaml"
        ];
        environment = {
          DT_ENV = "selfhosted";
          DT_SQLITE_PATH = "/donetick-data/donetick.db";
        };

        extraEnv =
          {
            DT_JWT_SECRET.fromFile = cfg.jwtSecretFile;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            DT_OAUTH2_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          };

        port = 2021;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "donetick";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:donetick";
        };
      };
    };
  };
}
