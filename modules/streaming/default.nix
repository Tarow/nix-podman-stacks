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

  cfg = config.nps.stacks.${stackName};
  storage = "${config.nps.storageBaseDir}/${stackName}";
  mediaStorage = "${config.nps.mediaStorageBaseDir}";

  mkServarrEnv = name: {
    PUID = config.nps.defaultUid;
    PGID = config.nps.defaultGid;
    "${name}__AUTH__METHOD" = "Forms";
    "${name}__AUTH__REQUIRED" = "DisabledForLocalAddresses";
  };
in {
  imports = import ../mkAliases.nix config lib stackName [
    gluetunName
    qbittorrentName
    jellyfinName
    sonarrName
    radarrName
    bazarrName
    prowlarrName
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
          description = "Additional Gluetun configuration settings.";
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
      flaresolverr.enable =
        lib.mkEnableOption "Flaresolverr"
        // {
          default = true;
        };
    }
    // (
      [
        sonarrName
        radarrName
        bazarrName
        prowlarrName
      ]
      |> lib.map (
        name:
          lib.nameValuePair name {
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
          }
      )
      |> lib.listToAttrs
    );

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf (cfg.jellyfin.enable && cfg.jellyfin.oidc.enable) {
      ${cfg.jellyfin.oidc.adminGroup} = {};
      ${cfg.jellyfin.oidc.userGroup} = {};
    };
    nps.stacks.authelia = lib.mkIf (cfg.jellyfin.enable && cfg.jellyfin.oidc.enable) {
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
    };

    nps.stacks.streaming.gluetun.settings = import ./gluetun_config.nix;

    services.podman.containers = {
      ${gluetunName} = lib.mkIf cfg.gluetun.enable {
        image = "docker.io/qmcgaw/gluetun:v3.40.0";
        addCapabilities = ["NET_ADMIN"];
        devices = ["/dev/net/tun:/dev/net/tun"];
        volumes = [
          "${storage}/${gluetunName}:/gluetun"
          "${cfg.gluetun.settings}:/gluetun/auth/config.toml"
        ];
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
          category = "Network & Administration";
          name = "Gluetun";
          settings = {
            description = "VPN client";
            icon = "gluetun";
            widget = {
              type = "gluetun";
              url = "http://${gluetunName}:8000";
            };
          };
        };
      };

      ${qbittorrentName} = lib.mkIf cfg.qbittorrent.enable {
        image = "docker.io/linuxserver/qbittorrent:5.1.2";
        dependsOnContainer = [gluetunName];
        network = lib.mkIf cfg.gluetun.enable (lib.mkForce ["container:${gluetunName}"]);
        volumes = [
          "${storage}/${qbittorrentName}:/config"
          "${mediaStorage}:/media"
        ];

        environment = {
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          UMASK = "022";
          WEBUI_PORT = 8080;
        };

        extraEnv = cfg.qbittorrent.extraEnv;

        stack = stackName;
        port = 8080;
        traefik.name = qbittorrentName;
        homepage = {
          category = "Media & Downloads";
          name = "qBittorrent";
          settings = {
            description = "BitTorrent Client";
            icon = "qbittorrent";
            widget.type = "qbittorrent";
          };
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
          image = "lscr.io/linuxserver/jellyfin:10.10.7";
          volumes =
            [
              "${storage}/${jellyfinName}:/config"
              "${mediaStorage}:/media"
            ]
            ++ lib.optional (cfg.jellyfin.oidc.enable) "${brandingXml}:/config/branding.xml";

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
            category = "Media & Downloads";
            name = "Jellyfin";
            settings = {
              description = "Media Server";
              icon = "jellyfin";
              widget.type = "jellyfin";
            };
          };
        };

      ${sonarrName} = lib.mkIf cfg.sonarr.enable {
        image = "lscr.io/linuxserver/sonarr:4.0.15";
        volumes = [
          "${storage}/${sonarrName}:/config"
          "${mediaStorage}:/media"
        ];
        environment = mkServarrEnv "SONARR";
        extraEnv = cfg.${sonarrName}.extraEnv;

        port = 8989;
        stack = stackName;
        traefik.name = sonarrName;
        homepage = {
          category = "Media & Downloads";
          name = "Sonarr";
          settings = {
            description = "Series Management";
            icon = "sonarr";
            widget.type = "sonarr";
          };
        };
      };

      ${radarrName} = lib.mkIf cfg.radarr.enable {
        image = "lscr.io/linuxserver/radarr:5.27.5";
        volumes = [
          "${storage}/${radarrName}:/config"
          "${mediaStorage}:/media"
        ];
        environment = mkServarrEnv "RADARR";
        extraEnv = cfg.${radarrName}.extraEnv;

        port = 7878;
        stack = stackName;
        traefik.name = radarrName;
        homepage = {
          category = "Media & Downloads";
          name = "Radarr";
          settings = {
            description = "Movie Management";
            icon = "radarr";
            widget.type = "radarr";
          };
        };
      };

      ${bazarrName} = lib.mkIf cfg.bazarr.enable {
        image = "lscr.io/linuxserver/bazarr:1.5.3";
        volumes = [
          "${storage}/${bazarrName}:/config"
          "${mediaStorage}:/media"
        ];
        environment = mkServarrEnv "BAZARR";
        extraEnv = cfg.${bazarrName}.extraEnv;

        port = 6767;
        stack = stackName;
        traefik.name = bazarrName;
        homepage = {
          category = "Media & Downloads";
          name = "Bazarr";
          settings = {
            description = "Subtitle Management";
            icon = "bazarr";
            widget.type = "bazarr";
          };
        };
      };

      ${prowlarrName} = lib.mkIf cfg.prowlarr.enable {
        image = "lscr.io/linuxserver/prowlarr:2.0.5";
        volumes = [
          "${storage}/${prowlarrName}:/config"
        ];
        environment = mkServarrEnv "PROWLARR";
        extraEnv = cfg.${prowlarrName}.extraEnv;

        port = 9696;
        stack = stackName;
        traefik.name = prowlarrName;
        homepage = {
          category = "Media & Downloads";
          name = "Prowlarr";
          settings = {
            description = "Indexer Management";
            icon = "prowlarr";
            widget.type = "prowlarr";
          };
        };
      };

      flaresolverr = lib.mkIf cfg.flaresolverr.enable {
        image = "ghcr.io/flaresolverr/flaresolverr:v3.4.1";
        volumes = [
          "${storage}/${prowlarrName}:/config"
        ];
        environment = {
          LOG_LEVEL = "info";
          LOG_HTML = false;
          CAPTCHA_SOLVER = "none";
        };

        stack = stackName;
        homepage = {
          category = "Media & Downloads";
          name = "Flaresolverr";
          settings = {
            icon = "flaresolverr";
            description = "Cloudflare Protection Bypass";
          };
        };
      };
    };
  };
}
