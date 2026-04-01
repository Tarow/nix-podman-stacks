{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "streaming";

  toml = pkgs.formats.toml {};

  gluetunName = "gluetun";
  qbittorrentName = "qbittorrent";
  jellyfinName = "jellyfin";
  sonarrName = "sonarr";
  radarrName = "radarr";
  bazarrName = "bazarr";
  prowlarrName = "prowlarr";
  quiName = "qui";
  seerrName = "seerr";
  profilarrName = "profilarr";

  category = "Media & Downloads";
  qbittorrentDescription = "BitTorrent Client";
  qbittorrentDisplayName = "qBittorrent";
  jellyfinDescription = "Media Server";
  jellyfinDisplayName = "Jellyfin";
  sonarrDescription = "Series Management";
  sonarrDisplayName = "Sonarr";
  radarrDescription = "Movie Management";
  radarrDisplayName = "Radarr";
  bazarrDescription = "Subtitle Management";
  bazarrDisplayName = "Bazarr";
  prolarrDescription = "Indexer Management";
  prowlarrDisplayName = "Prowlarr";
  quiDisplayName = "qui";
  quiDescription = "qBittorrent UI";
  seerrDescription = "Media Requests";
  seerrDisplayName = "Seerr";
  profilarrDisplayName = "Profilarr";
  profilarrDescription = "Configuration Management";

  gluetunCategory = "Network & Administration";
  gluetunDescription = "VPN client";
  gluetunDisplayName = "Gluetun";

  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";
  mediaStorage = "${config.nps.mediaStorageBaseDir}";

  mkArrOptions = name: {
    enable =
      lib.mkEnableOption name
      // {
        default = true;
      };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).
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
        default = name;
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
  };

  mkArrBase = name: let
    arrCfg = cfg.${name};
    upperName = lib.toUpper name;
  in {
    volumeMap = {
      config = "${storage}/${name}:/config";
      media = "${mediaStorage}:/media";
    };

    extraEnv =
      {
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
        "${upperName}__AUTH__METHOD" = "Forms";
        "${upperName}__AUTH__REQUIRED" = "DisabledForLocalAddresses";
      }
      // lib.optionalAttrs (arrCfg.db.type == "postgres") {
        "${upperName}__POSTGRES__HOST" = "${name}-db";
        "${upperName}__POSTGRES__USER" = arrCfg.db.username;
        "${upperName}__POSTGRES__PASSWORD".fromFile = arrCfg.db.passwordFile;
        "${upperName}__POSTGRES__MAINDB" = name;
        "${upperName}__POSTGRES__LOGDB" = "${name}_log";
      }
      // arrCfg.extraEnv;

    wantsContainer = lib.optional (arrCfg.db.type == "postgres") "${name}-db";

    stack = stackName;
    traefik.name = name;
  };

  mkArrPostgres = name: let
    arrCfg = cfg.${name};
  in
    lib.mkIf (arrCfg.db.type == "postgres") {
      image = "docker.io/postgres:18";
      volumeMap = let
        init = pkgs.writeText "init.sql" ''
          CREATE DATABASE ${name}_log;
        '';
      in {
        # Needs extra folder, otherwise its mounted into *arr, which will chown all folders -> db fails to start
        data = "${storage}/${name}_postgres:/var/lib/postgresql";
        initSql = "${init}:/docker-entrypoint-initdb.d/init.sql";
      };

      extraEnv = {
        POSTGRES_USER = arrCfg.db.username;
        POSTGRES_DB = name;
        POSTGRES_PASSWORD.fromFile = arrCfg.db.passwordFile;
      };

      extraConfig.Container = {
        Notify = "healthy";
        HealthCmd = "pg_isready -h 127.0.0.1 -d ${name}_log -U ${arrCfg.db.username}";
        HealthInterval = "10s";
        HealthTimeout = "10s";
        HealthRetries = 5;
        HealthStartPeriod = "10s";
        HealthOnFailure = "kill";
      };

      stack = stackName;
      glance = {
        inherit category;
        name = "Postgres";
        parent = name;
        icon = "di:postgres";
      };
    };

  arrDbs =
    lib.genAttrs'
    [
      sonarrName
      radarrName
      bazarrName
      prowlarrName
    ]
    (name: lib.nameValuePair "${name}-db" (mkArrPostgres name));
in {
  imports = import ../mkAliases.nix config lib stackName [
    gluetunName
    qbittorrentName
    jellyfinName
    sonarrName
    radarrName
    bazarrName
    prowlarrName
    quiName
    seerrName
    profilarrName
  ];

  options.nps.stacks.${stackName} =
    {
      enable = lib.mkEnableOption stackName;
      gluetun = {
        enable =
          lib.mkEnableOption "Gluetun"
          // {
            default = true;
          };
        vpnProvider = lib.mkOption {
          type = lib.types.str;
          description = "The VPN provider to use with Gluetun.";
        };
        wireguardPrivateKeyFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to the file containing the Wireguard private key. Will be used to set the `WIREGUARD_PRIVATE_KEY` environment variable.";
        };
        wireguardPresharedKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to the file containing the Wireguard pre-shared key. Will be used to set the `WIREGUARD_PRESHARED_KEY` environment variable.";
        };
        wireguardAddressesFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to the file containing the Wireguard addresses. Will be used to set the `WIREGUARD_ADDRESSES` environment variable.";
        };
        extraEnv = lib.mkOption {
          type = (import ../types.nix lib).extraEnv;
          default = {};
          description = ''
            Extra environment variables to set for the container.
            Variables can be either set directly or sourced from a file (e.g. for secrets).

            See <https://github.com/qdm12/gluetun-wiki/tree/main/setup/options>
          '';
          example = {
            SERVER_NAMES = "Alderamin,Alderamin";
            HTTP_CONTROL_SERVER_LOG = "off";
            HTTPPROXY_PASSWORD = {
              fromFile = "/run/secrets/http_proxy_password";
            };
          };
        };
        settings = lib.mkOption {
          type = toml.type;
          apply = toml.generate "config.toml";
          description = ''
            Additional Gluetun configuration settings

            See <https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/control-server.md#configuration>
          '';
        };
      };
      qbittorrent = {
        enable =
          lib.mkEnableOption "qBittorrent"
          // {
            default = true;
          };
        extraEnv = lib.mkOption {
          type = (import ../types.nix lib).extraEnv;
          default = {};
          description = ''
            Extra environment variables to set for the container.
            Variables can be either set directly or sourced from a file (e.g. for secrets).

            See <https://docs.linuxserver.io/images/docker-qbittorrent/#environment-variables-e>
          '';
          example = {
            TORRENTING_PORT = "6881";
          };
        };
      };
      jellyfin = {
        enable =
          lib.mkEnableOption "Jellyfin"
          // {
            default = true;
          };
        oidc = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
              and setup the necessary configuration file.

              The plugin configuration will be automatically provided, the plugin itself has to be installed in the
              Jellyfin Web-UI tho.

              For details, see:

              - <https://www.authelia.com/integration/openid-connect/clients/jellyfin/>
              - <https://github.com/9p4/jellyfin-plugin-sso>
            '';
          };
          clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
          clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.jellyfin.oidc.clientSecretFile;
          adminGroup = lib.mkOption {
            type = lib.types.str;
            default = "${jellyfinName}_admin";
            description = "Users of this group will be assigned admin rights in Jellyfin";
          };
          userGroup = lib.mkOption {
            type = lib.types.str;
            default = "${jellyfinName}_user";
            description = "Users of this group will be able to log in";
          };
        };
      };
      profilarr.enable = lib.mkEnableOption "Profilarr";
      seerr.enable = lib.mkEnableOption "Seerr";
      qui = {
        enable = lib.mkEnableOption "qui";
        adminUsername = lib.mkOption {
          type = lib.types.str;
          default = "admin";
          description = ''
            Admin username to access the dashboard.
          '';
        };
        adminPasswordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Path to the file containing the admin password.
            If set, an admin user will be created automatically.
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

              - <https://getqui.com/docs/configuration/oidc>
            '';
          };
          clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
          clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.qui.oidc.clientSecretFile;
          userGroup = lib.mkOption {
            type = lib.types.str;
            default = "${quiName}_user";
            description = "Users of this group will be able to log in";
          };
        };
      };
      flaresolverr.enable =
        lib.mkEnableOption "Flaresolverr"
        // {
          default = true;
        };
    }
    // (
      lib.genAttrs
      [
        sonarrName
        radarrName
        bazarrName
        prowlarrName
      ]
      mkArrOptions
    );

  config = lib.mkIf cfg.enable {
    # If Flaresolverr is enabled, enable it & connect it to the streaming stack network
    nps.stacks.flaresolverr.enable = lib.mkIf cfg.flaresolverr.enable true;
    nps.containers.flaresolverr = lib.mkIf cfg.flaresolverr.enable {
      network = [stackName];
    };

    nps.stacks.lldap.bootstrap.groups = lib.mkMerge [
      (lib.mkIf (cfg.jellyfin.enable && cfg.jellyfin.oidc.enable) {
        ${cfg.jellyfin.oidc.adminGroup} = {};
        ${cfg.jellyfin.oidc.userGroup} = {};
      })
      (lib.mkIf (cfg.qui.enable && cfg.qui.oidc.enable) {
        ${cfg.qui.oidc.userGroup} = {};
      })
    ];
    nps.stacks.authelia = lib.mkMerge [
      (lib.mkIf (cfg.jellyfin.enable && cfg.jellyfin.oidc.enable) {
        oidc.clients.${jellyfinName} = {
          client_name = "Jellyfin";
          client_secret = cfg.jellyfin.oidc.clientSecretHash;
          public = false;
          authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
          require_pkce = true;
          pkce_challenge_method = "S256";
          pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
          token_endpoint_auth_method = "client_secret_post";
          redirect_uris = [
            "${cfg.containers.${jellyfinName}.traefik.serviceUrl}/sso/OID/redirect/authelia"
          ];
        };
      })
      (lib.mkIf (cfg.qui.enable && cfg.qui.oidc.enable) {
        oidc.clients.${quiName} = {
          client_name = quiDisplayName;
          client_secret = cfg.qui.oidc.clientSecretHash;
          public = false;
          authorization_policy = quiName;
          require_pkce = false;
          pkce_challenge_method = "";
          pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
          token_endpoint_auth_method = "client_secret_post";
          redirect_uris = [
            "${cfg.containers.${quiName}.traefik.serviceUrl}/api/auth/oidc/callback"
          ];
        };
        # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level
        # See <https://github.com/autobrr/qui/discussions/1032>
        settings.identity_providers.oidc.authorization_policies.${quiName} = {
          default_policy = "deny";
          rules = [
            {
              policy = config.nps.stacks.authelia.defaultAllowPolicy;
              subject = "group:${cfg.qui.oidc.userGroup}";
            }
          ];
        };
      })
    ];

    nps.stacks.streaming.gluetun.settings = import ./gluetun_config.nix;

    services.podman.containers =
      {
        ${gluetunName} = lib.mkIf cfg.gluetun.enable {
          image = "docker.io/qmcgaw/gluetun:v3.41.1";
          addCapabilities = ["NET_ADMIN" "NET_RAW"];
          devices = ["/dev/net/tun:/dev/net/tun"];
          volumeMap = {
            data = "${storage}/${gluetunName}:/gluetun";
            setings = "${cfg.gluetun.settings}:/gluetun/auth/config.toml";
          };
          environment = {
            WIREGUARD_MTU = 1320;
            HTTP_CONTROL_SERVER_LOG = "off";
            VPN_SERVICE_PROVIDER = cfg.gluetun.vpnProvider;
            VPN_TYPE = "wireguard";
            UPDATER_PERIOD = "12h";
            HTTPPROXY = "on";
            HEALTH_VPN_DURATION_INITIAL = "60s";
          };
          extraEnv =
            {
              WIREGUARD_PRIVATE_KEY.fromFile = cfg.gluetun.wireguardPrivateKeyFile;
              WIREGUARD_PRESHARED_KEY.fromFile = cfg.gluetun.wireguardPresharedKeyFile;
              WIREGUARD_ADDRESSES.fromFile = cfg.gluetun.wireguardAddressesFile;
            }
            // cfg.gluetun.extraEnv;

          network = [config.nps.stacks.traefik.network.name];

          stack = stackName;
          port = 8888;
          homepage = {
            category = gluetunCategory;
            name = gluetunDisplayName;
            settings = {
              description = gluetunDescription;
              icon = "gluetun";
              widget = {
                type = "gluetun";
                url = "http://${gluetunName}:8000";
              };
            };
          };
          glance = {
            category = gluetunCategory;
            description = gluetunDescription;
            name = gluetunDisplayName;
            id = gluetunName;
            icon = "di:gluetun";
          };
        };

        ${qbittorrentName} = lib.mkIf cfg.qbittorrent.enable {
          image = "docker.io/linuxserver/qbittorrent:5.1.4";

          network = lib.mkIf cfg.gluetun.enable (lib.mkForce ["container:${gluetunName}"]);
          volumeMap = {
            config = "${storage}/${qbittorrentName}:/config";
            media = "${mediaStorage}:/media";
          };

          environment = {
            PUID = config.nps.defaultUid;
            PGID = config.nps.defaultGid;
            UMASK = "022";
            WEBUI_PORT = 8080;
          };

          extraEnv = cfg.qbittorrent.extraEnv;
          dependsOnContainer = lib.mkIf cfg.gluetun.enable [gluetunName];

          stack = stackName;
          port = 8080;
          traefik.name = qbittorrentName;
          homepage = {
            inherit category;
            name = qbittorrentDisplayName;
            settings = {
              description = qbittorrentDescription;
              icon = "qbittorrent";
              widget.type = "qbittorrent";
            };
          };
          glance = {
            inherit category;
            description = qbittorrentDescription;
            name = qbittorrentDisplayName;
            id = qbittorrentName;
            icon = "di:qbittorrent";
          };
        };

        ${quiName} = lib.mkIf cfg.qui.enable {
          image = "ghcr.io/autobrr/qui:v1.15.0";
          volumeMap = {
            config = "${storage}/${quiName}:/config";
            media = "${mediaStorage}:/media";
            adminPassword = lib.mkIf (cfg.qui.adminPasswordFile != null) "${cfg.qui.adminPasswordFile}:/run/secrets/admin_password";
          };

          extraEnv = lib.optionalAttrs cfg.qui.oidc.enable {
            QUI__OIDC_ENABLED = true;
            QUI__OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
            QUI__OIDC_CLIENT_ID = quiName;
            QUI__OIDC_CLIENT_SECRET.fromFile = cfg.qui.oidc.clientSecretFile;
            QUI__OIDC_REDIRECT_URL = "${cfg.containers.${quiName}.traefik.serviceUrl}/api/auth/oidc/callback";
            QUI__OIDC_DISABLE_BUILT_IN_LOGIN = true;
          };

          extraConfig.Service.ExecStartPost =
            lib.optional (cfg.qui.adminPasswordFile != null)
            "${lib.getExe config.nps.package} exec ${quiName} /bin/sh -c 'qui create-user --username ${cfg.qui.adminUsername} < /run/secrets/admin_password'";

          wantsContainer =
            (lib.optional cfg.qbittorrent.enable qbittorrentName)
            ++ (lib.optional cfg.qui.oidc.enable "authelia");

          stack = stackName;
          port = 7476;
          traefik.name = quiName;
          homepage = {
            inherit category;
            name = quiDisplayName;
            settings = {
              description = quiDescription;
              icon = "qui";
            };
          };
          glance = {
            inherit category;
            description = quiDescription;
            name = quiDisplayName;
            id = quiName;
            icon = "di:qui";
          };
        };

        ${jellyfinName} = let
          brandingXml = pkgs.writeText "branding.xml" ''
            <?xml version="1.0" encoding="utf-8"?>
            <BrandingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
              <LoginDisclaimer>&lt;form action="${config.nps.containers.jellyfin.traefik.serviceUrl}/sso/OID/start/authelia"&gt;
              &lt;button class="raised block emby-button button-submit"&gt;
                Sign in with Authelia
              &lt;/button&gt;
            &lt;/form&gt;</LoginDisclaimer>
              <CustomCss>a.raised.emby-button {
              padding: 0.9em 1em;
              color: inherit !important;
            }
            .disclaimerContainer {
              display: block;
            }</CustomCss>
              <SplashscreenEnabled>true</SplashscreenEnabled>
            </BrandingOptions>
          '';
        in
          lib.mkIf cfg.jellyfin.enable {
            image = "lscr.io/linuxserver/jellyfin:10.11.7";
            volumeMap = {
              config = "${storage}/${jellyfinName}:/config";
              media = "${mediaStorage}:/media";
              brandingXml = lib.mkIf (cfg.jellyfin.oidc.enable) "${brandingXml}:/config/branding.xml";
            };

            templateMount = lib.optional cfg.jellyfin.oidc.enable {
              templatePath = pkgs.writeText "oidc-template" (
                import ./jellyfin_sso_config.nix {
                  autheliaUri = config.nps.containers.authelia.traefik.serviceUrl;
                  clientId = jellyfinName;
                  adminGroup = cfg.jellyfin.oidc.adminGroup;
                  userGroup = cfg.jellyfin.oidc.userGroup;
                  clientSecretFile = cfg.jellyfin.oidc.clientSecretFile;
                }
              );
              destPath = "/config/data/plugins/configurations/SSO-Auth.xml";
            };

            devices = ["/dev/dri:/dev/dri"];
            environment = {
              PUID = config.nps.defaultUid;
              PGID = config.nps.defaultGid;
              JELLYFIN_PublishedServerUrl =
                config.services.podman.containers.${jellyfinName}.traefik.serviceUrl;
            };

            port = 8096;
            stack = stackName;
            traefik.name = jellyfinName;
            homepage = {
              inherit category;
              name = jellyfinDisplayName;
              settings = {
                description = jellyfinDescription;
                icon = "jellyfin";
                widget.type = "jellyfin";
              };
            };
            glance = {
              inherit category;
              description = jellyfinDescription;
              name = jellyfinDisplayName;
              id = jellyfinName;
              icon = "di:jellyfin";
            };
          };

        ${seerrName} = lib.mkIf cfg.seerr.enable {
          image = "ghcr.io/seerr-team/seerr:v3.1.0";
          user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
          volumeMap.config = "${storage}/${seerrName}/config:/app/config";
          environment.PORT = 5055;

          port = 5055;
          traefik.name = seerrName;
          stack = stackName;
          homepage = {
            inherit category;
            name = seerrDisplayName;
            settings = {
              description = seerrDescription;
              icon = "overseerr";
            };
          };
          glance = {
            inherit category;
            description = seerrDescription;
            name = seerrDisplayName;
            id = seerrName;
            icon = "di:overseerr";
          };
        };

        ${profilarrName} = lib.mkIf cfg.profilarr.enable {
          image = "docker.io/santiagosayshey/profilarr:v1.1.4";
          volumeMap.config = "${storage}/${profilarrName}/config:/config";

          environment = {
            PUID = config.nps.defaultUid;
            PGID = config.nps.defaultGid;
          };

          port = 6868;
          traefik.name = profilarrName;
          stack = stackName;
          homepage = {
            inherit category;
            name = profilarrDisplayName;
            settings = {
              description = profilarrDescription;
              icon = "profilarr";
            };
          };
          glance = {
            inherit category;
            description = profilarrDescription;
            name = profilarrDisplayName;
            id = seerrName;
            icon = "di:profilarr";
          };
        };

        ${sonarrName} = lib.mkIf cfg.sonarr.enable (mkArrBase sonarrName
          // {
            image = "lscr.io/linuxserver/sonarr:4.0.17";
            port = 8989;

            homepage = {
              inherit category;
              name = sonarrDisplayName;
              settings = {
                description = sonarrDescription;
                icon = "sonarr";
                widget.type = "sonarr";
              };
            };
            glance = {
              inherit category;
              description = sonarrDescription;
              name = sonarrDisplayName;
              id = sonarrName;
              icon = "di:sonarr";
            };
          });

        ${radarrName} = lib.mkIf cfg.radarr.enable (mkArrBase radarrName
          // {
            image = "lscr.io/linuxserver/radarr:6.0.4";
            port = 7878;

            homepage = {
              inherit category;
              name = radarrDisplayName;
              settings = {
                description = radarrDescription;
                icon = "radarr";
                widget.type = "radarr";
              };
            };
            glance = {
              inherit category;
              description = radarrDescription;
              name = radarrDisplayName;
              id = radarrName;
              icon = "di:radarr";
            };
          });

        ${bazarrName} = lib.mkIf cfg.bazarr.enable (mkArrBase bazarrName
          // {
            image = "lscr.io/linuxserver/bazarr:1.5.6";
            port = 6767;

            homepage = {
              inherit category;
              name = bazarrDisplayName;
              settings = {
                description = bazarrDescription;
                icon = "bazarr";
                widget.type = "bazarr";
              };
            };
            glance = {
              inherit category;
              description = bazarrDescription;
              name = bazarrDisplayName;
              id = bazarrName;
              icon = "di:bazarr";
            };
          });

        ${prowlarrName} = lib.mkIf cfg.prowlarr.enable (mkArrBase prowlarrName
          // {
            image = "lscr.io/linuxserver/prowlarr:2.3.0";
            port = 9696;

            homepage = {
              inherit category;
              name = prowlarrDisplayName;
              settings = {
                description = prolarrDescription;
                icon = "prowlarr";
                widget.type = "prowlarr";
              };
            };
            glance = {
              inherit category;
              description = prolarrDescription;
              name = prowlarrDisplayName;
              id = prowlarrName;
              icon = "di:prowlarr";
            };
          });
      }
      // arrDbs;
  };
}
