{
  config,
  lib,
  ...
}: let
  name = "calibre";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Media & Downloads";
  description = "Ebook Library";
  displayName = "Calibre-Web-Automated";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/crocodilestick/calibre-web-automated:v4.0.5";
      volumeMap = {
        config = "${storage}/config:/config";
        ingest = "${storage}/ingest:/cwa-book-ingest";
        library = "${storage}/library:/calibre-library";
      };
      environment = {
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
      };
      port = 8083;

      stack = name;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "calibre-web";
          widget.type = "calibreweb";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:calibre-web";
      };
    };
  };
}
