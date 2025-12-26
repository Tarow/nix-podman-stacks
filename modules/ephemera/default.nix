{
  config,
  lib,
  ...
}: let
  name = "ephemera";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Media & Downloads";
  description = "Book Downloader";
  displayName = "Ephemera";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    downloadDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${storage}/ingest";
      defaultText = lib.literalExpression ''"''${config.nps.storageBaseDir}/${name}/ingest"'';
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

        See <https://github.com/OrwellianEpilogue/ephemera?tab=readme-ov-file#optional-environment-variables>
      '';
      example = {
        AA_API_KEY = {
          fromFile = "/run/secrets/secret_name";
        };
        LG_BASE_URL = "https://some-gen.li";
      };
    };
    flaresolverr.enable =
      lib.mkEnableOption "Flaresolverr"
      // {
        default = true;
      };
  };

  config = lib.mkIf cfg.enable {
    # If Flaresolverr is enabled, enable it & connect it to the ephemera network
    nps.stacks.flaresolverr.enable = lib.mkIf cfg.flaresolverr.enable true;
    nps.containers.flaresolverr = lib.mkIf cfg.flaresolverr.enable {
      network = [name];
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/orwellianepilogue/ephemera:1.4.2";
      volumes = [
        "${storage}/data:/app/data"
        "${storage}/downloads:/app/downloads"
        "${cfg.downloadDirectory}:/app/ingest"
      ];
      extraConfig.Container = {
        HealthCmd = "wget --no-verbose --tries=1 --spider http://127.0.0.1:8286/health";
        HealthInterval = "30s";
        HealthTimeout = "10s";
        HealthRetries = 5;
        HealthStartPeriod = "10s";
      };

      extraEnv =
        {
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          AA_BASE_URL = lib.mkDefault "https://annas-archive.org";
          LG_BASE_URL = lib.mkDefault "https://libgen.bz";
        }
        // lib.optionalAttrs cfg.flaresolverr.enable {
          FLARESOLVERR_URL = config.services.podman.containers.flaresolverr.traefik.serviceAddressInternal;
        }
        // cfg.extraEnv;

      stack = name;
      port = 8286;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "sh-ephemera";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "sh:ephemera";
      };
    };
  };
}
