{
  config,
  lib,
  ...
}: let
  name = "navidrome";
  storage = "${config.nps.storageBaseDir}/${name}";
  mediaStorage = config.nps.mediaStorageBaseDir;
  cfg = config.nps.stacks.${name};

  category = "Media & Downloads";
  displayName = "Navidrome";
  description = "Music Server and Streamer";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://www.navidrome.org/docs/usage/configuration/options/>
      '';
      example = {
        ND_LOGLEVEL = "debug";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/deluan/navidrome:0.61.0";
      volumeMap = {
        data = "${storage}/data:/data";
        music = "${mediaStorage}/music:/music:ro";
      };

      extraEnv =
        {
          ND_BASEURL = config.nps.containers.${name}.traefik.serviceUrl;
        }
        // cfg.extraEnv;

      port = 4533;
      traefik.name = name;

      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "navidrome";
          widget.type = "navidrome";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:navidrome";
      };
    };
  };
}
