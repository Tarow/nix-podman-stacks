{
  config,
  lib,
  ...
}: let
  name = "filebrowser";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  displayName = "FileBrowser";
  description = "Web-based File Manager";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    mounts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      apply = lib.mapAttrs (k: v: builtins.replaceStrings ["//"] ["/"] "/srv/${v}");
      description = ''
        Mount points for the file browser.
        Format: `{ 'hostPath' = 'containerPath' }`
      '';
      example = {
        "/mnt/ext/data" = "/data";
        "/home/foo/media" = "/media";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/filebrowser/filebrowser:v2.62.1-s6";
      volumeMap = {
        database = "${storage}/database:/database";
        config = "${storage}/config:/config";
      };

      volumes = lib.mapAttrsToList (k: v: "${k}:${v}") cfg.mounts;

      environment = {
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
      };
      port = 80;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "filebrowser";
        };
      };
      glance = {
        inherit category description;
        id = name;
        name = displayName;
        icon = "di:filebrowser";
      };
    };
  };
}
