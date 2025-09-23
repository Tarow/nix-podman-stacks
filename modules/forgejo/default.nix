{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "forgejo";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  ini = pkgs.formats.ini {};

  category = "General";
  description = "Git Server";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr ini.type;
      default = null;
      apply = settings:
        if (settings != null)
        then ini.generate "app.ini" settings
        else null;
      description = ''
        Optional app settings for Forgejo.
        For a full list of options, refer to the [Forgejo documentation](https://forgejo.org/docs/latest/admin/config-cheat-sheet/).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "codeberg.org/forgejo/forgejo:12";
      volumes =
        [
          "${storage}/data:/data"
        ]
        ++ lib.optional (cfg.settings != null) "${cfg.settings}:/data/gitea/conf/app.ini";
      ports = ["222:22"];

      port = 3000;
      traefik.name = name;
      homepage = {
        inherit category;
        settings = {
          inherit description;
          icon = "forgejo";
        };
      };
      glance = {
        inherit category description;
        id = name;
        icon = "di:forgejo";
      };
    };
  };
}
