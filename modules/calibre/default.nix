{
  config,
  lib,
  ...
}: let
  name = "calibre";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Ebook Library";
  downloaderDescription = "Book Downloader for Calibre Web";
in {
  imports = import ../mkAliases.nix config lib name [name "${name}-downloader"];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/crocodilestick/calibre-web-automated:V3.1.1";
      volumes = [
        "${storage}/config:/config"
        "${storage}/ingest:/cwa-book-ingest"
        "${storage}/library:/calibre-library"
      ];
      environment = {
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
      };
      port = 8083;

      stack = name;
      traefik.name = name;
      homepage = {
        inherit category;
        settings = {
          inherit description;
          icon = "calibre-web";
          widget.type = "calibreweb";
        };
      };
      glance = {
        inherit category description;
        id = name;
        icon = "di:calibre-web";
      };
    };

    services.podman.containers."${name}-downloader" = let
      ingestDir = "/cwa-book-ingest";
      port = 8084;
    in {
      image = "ghcr.io/calibrain/calibre-web-automated-book-downloader:20250815";
      environment = {
        FLASK_PORT = port;
        FLASK_DEBUG = false;
        INGEST_DIR = ingestDir;
        APP_ENV = "prod";
        BOOK_LANGUAGE = "en,de";
        UID = config.nps.defaultUid;
        GID = config.nps.defaultGid;
      };
      volumes = [
        "${storage}/ingest:${ingestDir}"
      ];

      port = port;
      stack = name;
      traefik.name = "calibre-downloader";
      homepage = {
        inherit category;
        settings = {
          description = downloaderDescription;
          icon = "sh-cwa-book-downloader";
        };
      };
      glance = {
        inherit category;
        id = name;
        description = downloaderDescription;
        icon = "di:sh-cwa-book-downloader";
      };
    };
  };
}
