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
    flaresolverr.enable =
      lib.mkEnableOption "Flaresolverr"
      // {
        default = true;
      };
  };

  config = lib.mkIf cfg.enable {
    # If Flaresolverr is enabled, enable it & connect it to the shelfmark network
    nps.stacks.flaresolverr.enable = lib.mkIf cfg.flaresolverr.enable true;
    nps.containers.flaresolverr = lib.mkIf cfg.flaresolverr.enable {
      network = [name];
    };

    services.podman.containers."${name}" = let
      port = 8084;
      ingestDir = "/books";
    in {
      image = "ghcr.io/calibrain/shelfmark-lite:v1.2.0";
      extraEnv =
        {
          FLASK_PORT = port;
          INGEST_DIR = ingestDir;
          SEARCH_MODE = "universal";
          OPENLIBRARY_ENABLED = true;
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          ONBOARDING = false;
        }
        // lib.optionalAttrs cfg.flaresolverr.enable {
          USE_CF_BYPASS = true;
          USING_EXTERNAL_BYPASSER = true;
          EXT_BYPASSER_URL = "http://flaresolverr:8191";
        }
        // cfg.extraEnv;
      volumeMap = {
        config = "${storage}/config:/config";
        ingest = "${cfg.downloadDirectory}:${ingestDir}";
      };

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
