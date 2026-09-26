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

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    libraryPath = lib.mkOption {
      type = lib.types.str;
      default = "${storage}/library";
      defaultText = lib.literalExpression ''"''${config.nps.storageBaseDir}/${name}/library"'';
      description = ''
        Host directory where the Calibre library is stored.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/crocodilestick/calibre-web-automated:v4.0.6";
      volumeMap = {
        config = "${storage}/config:/config";
        ingest = "${storage}/ingest:/cwa-book-ingest";
        library = "${cfg.libraryPath}:/calibre-library";
      };
      environment = {
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
      };
      port = 8083;

      stack = name;
      traefik.name = name;
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:calibre-web";
      };
      homepage.settings.widget.type = "calibreweb";
    };
  };
}
