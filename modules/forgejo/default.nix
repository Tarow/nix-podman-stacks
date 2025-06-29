{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "forgejo";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};

  ini = pkgs.formats.ini {};
in {
  imports = import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr ini.type;
      default = null;
      apply = settings:
        if (settings != null)
        then ini.generate "app.ini" settings
        else null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "codeberg.org/forgejo/forgejo:11";
      volumes =
        [
          "${storage}/data:/data"
        ]
        ++ lib.optional (cfg.settings != null) "${cfg.settings}:/data/gitea/conf/app.ini";
      ports = ["222:22"];

      port = 3000;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "Forgejo";
        settings = {
          description = "Git Server";
          icon = "forgejo";
        };
      };
    };
  };
}
