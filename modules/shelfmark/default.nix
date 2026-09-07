{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "shelfmark";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Media & Downloads";
  description = "Book Downloader";
  displayName = "Shelfmark";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    downloadDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${storage}/books";
      defaultText = lib.literalExpression ''"''${config.nps.storageBaseDir}/${name}/books"'';
      description = ''
        Final host directory where downloads will be placed.
        To automatically ingest books in other applications such as CWA or Booklore, set this to the respective app's import directory.
      '';
      example = lib.literalExpression ''
        "''${config.nps.storageBaseDir}/booklore/bookdrop"
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/calibrain/shelfmark/blob/main/docs/environment-variables.md>
      '';
      example = {
        SOME_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        SOME_VALUE = "some_value";
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

          - <https://github.com/calibrain/shelfmark/blob/main/docs/environment-variables.md#security>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = "Users of this group will be assigned admin rights";
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users must be a part of this group to be able to log in.";
      };
    };
    useFlaresolverr = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable the Flaresolverr stack and connect it to the Shelfmark network.
        Shelfmark uses Flaresolverr to bypass Cloudflare protection.
      '';
    };
    useProwlarr = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable the Prowlarr stack and connect it to the Shelfmark network.
        Sets `PROWLARR_ENABLED` and `PROWLARR_URL`.
        You will likely also need to set `PROWLARR_API_KEY` via `extraEnv`
        (Settings > General > API Key).
      '';
    };
    useQbittorrent = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable the qBittorrent stack and connect it to the Shelfmark network.
        Sets `PROWLARR_TORRENT_CLIENT`, `QBITTORRENT_URL`, `QBITTORRENT_CATEGORY` and `QBITTORRENT_CATEGORY_AUDIOBOOK`.
        If authentication isn't bypassed in qBittorrent, you may need to set credentials via `extraEnv` (`QBITTORRENT_USERNAME`/`QBITTORRENT_PASSWORD` or `QBITTORRENT_API_KEY`).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.flaresolverr.enable = lib.mkIf cfg.useFlaresolverr true;
    nps.stacks.prowlarr.enable = lib.mkIf cfg.useProwlarr true;
    nps.stacks.qbittorrent.enable = lib.mkIf cfg.useQbittorrent true;
    # Attach the external stacks' containers to the shelfmark network.
    # For qBittorrent, attach Gluetun when the VPN is enabled, otherwise qBittorrent directly
    nps.containers = lib.mkMerge [
      (lib.mkIf cfg.useFlaresolverr {
        flaresolverr.network = [name];
      })
      (lib.mkIf cfg.useProwlarr {
        prowlarr.network = [name];
      })
      (lib.mkIf cfg.useQbittorrent {
        ${
          if config.nps.stacks.qbittorrent.gluetun.enable
          then "gluetun"
          else "qbittorrent"
        }.network = [name];
      })
    ];

    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.adminGroup} = {};
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/oidc/callback"
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

    services.podman.containers."${name}" = let
      port = 8084;
      ingestDir = "/books";
    in {
      image = "ghcr.io/calibrain/shelfmark-lite:v1.3.15";
      volumeMap = {
        config = "${storage}/config:/config";
        ingest = "${cfg.downloadDirectory}:${ingestDir}";
      };

      extraEnv =
        {
          FLASK_PORT = port;
          INGEST_DIR = ingestDir;
          SEARCH_MODE = "universal";
          OPENLIBRARY_ENABLED = true;
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          ONBOARDING = false;
          AUTH_METHOD = lib.mkDefault "none";
        }
        // lib.optionalAttrs cfg.oidc.enable {
          AUTH_METHOD = "oidc";
          OIDC_DISCOVERY_URL = config.nps.containers.authelia.traefik.serviceUrl + "/.well-known/openid-configuration";
          OIDC_CLIENT_ID = name;
          OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          OIDC_SCOPES = "openid,email,profile";
          OIDC_GROUP_CLAIM = "groups";
          OIDC_ADMIN_GROUP = cfg.oidc.adminGroup;
          OIDC_USE_ADMIN_GROUP = true;
          OIDC_AUTO_PROVISION = true;
          HIDE_LOCAL_AUTH = lib.mkDefault true;
        }
        // lib.optionalAttrs cfg.useFlaresolverr {
          USE_CF_BYPASS = true;
          USING_EXTERNAL_BYPASSER = true;
          EXT_BYPASSER_URL = "http://flaresolverr:8191";
        }
        // lib.optionalAttrs cfg.useProwlarr {
          PROWLARR_ENABLED = lib.mkDefault true;
          PROWLARR_URL = lib.mkDefault "http://${config.nps.containers.prowlarr.traefik.serviceAddressInternal}";
        }
        // lib.optionalAttrs cfg.useQbittorrent {
          PROWLARR_TORRENT_CLIENT = lib.mkDefault "qbittorrent";
          QBITTORRENT_URL = lib.mkDefault "http://${config.nps.containers.qbittorrent.traefik.serviceAddressInternal}";
          QBITTORRENT_CATEGORY = lib.mkDefault "ebooks";
          QBITTORRENT_CATEGORY_AUDIOBOOK = lib.mkDefault "audiobooks";
        }
        // cfg.extraEnv;

      port = port;
      traefik.name = name;
      stack = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          description = description;
          icon = "shelfmark";
        };
      };
      glance = {
        inherit category;
        id = name;
        name = displayName;
        description = description;
        icon = "di:shelfmark.webp";
      };
    };
  };
}
