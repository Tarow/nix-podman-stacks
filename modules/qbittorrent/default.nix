{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "qbittorrent";
  cfg = config.nps.stacks.${name};

  toml = pkgs.formats.toml {};

  gluetunName = "gluetun";
  qbittorrentName = "qbittorrent";
  quiName = "qui";

  category = "Media & Downloads";
  gluetunCategory = "Network & Administration";
  gluetunDescription = "VPN client";
  gluetunDisplayName = "Gluetun";
  qbittorrentDescription = "BitTorrent Client";
  qbittorrentDisplayName = "qBittorrent";
  quiDisplayName = "qui";
  quiDescription = "qBittorrent UI";

  storage = "${config.nps.storageBaseDir}/${name}";
  mediaStorage = "${config.nps.mediaStorageBaseDir}";
in {
  imports = import ../mkAliases.nix config lib name [
    gluetunName
    qbittorrentName
    quiName
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

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
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.qbittorrent.gluetun.settings = import ./gluetun_config.nix;

    nps.stacks.lldap.bootstrap.groups = lib.mkIf (cfg.qui.enable && cfg.qui.oidc.enable) {
      ${cfg.qui.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf (cfg.qui.enable && cfg.qui.oidc.enable) {
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
    };

    services.podman.containers = {
      ${gluetunName} = lib.mkIf cfg.gluetun.enable {
        image = "docker.io/qmcgaw/gluetun:v3.41.3";
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
            WIREGUARD_PRESHARED_KEY = lib.mkIf (cfg.gluetun.wireguardPresharedKeyFile != null) {fromFile = cfg.gluetun.wireguardPresharedKeyFile;};
            WIREGUARD_ADDRESSES = lib.mkIf (cfg.gluetun.wireguardAddressesFile != null) {fromFile = cfg.gluetun.wireguardAddressesFile;};
          }
          // cfg.gluetun.extraEnv;

        network = [config.nps.stacks.traefik.network.name];

        stack = name;
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

      ${qbittorrentName} = {
        image = "docker.io/linuxserver/qbittorrent:5.2.3";

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

        extraEnv = cfg.extraEnv;
        dependsOnContainer = lib.mkIf cfg.gluetun.enable [gluetunName];

        stack = name;
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
        image = "ghcr.io/autobrr/qui:v1.28.0";
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

        wantsContainer = [qbittorrentName] ++ lib.optional cfg.qui.oidc.enable "authelia";

        stack = name;
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
    };
  };
}
