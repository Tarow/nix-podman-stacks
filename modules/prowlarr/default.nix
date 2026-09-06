{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "prowlarr";
  cfg = config.nps.stacks.${name};

  category = "Media & Downloads";
  displayName = "Prowlarr";
  description = "Indexer Management";

  storage = "${config.nps.storageBaseDir}/${name}";
  mediaStorage = "${config.nps.mediaStorageBaseDir}";

  arrlib = import ../arrlib.nix {
    inherit
      config
      lib
      pkgs
      storage
      mediaStorage
      category
      ;
    stackName = name;
  };
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = let
    o = arrlib.mkArrOptions name;
  in {
    enable = o.enable // {default = false;};
    extraEnv = o.extraEnv;
    db = o.db;
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers =
      {
        ${name} =
          arrlib.mkArrBase name
          // {
            image = "lscr.io/linuxserver/prowlarr:2.5.2";
            port = 9696;

            homepage = {
              inherit category;
              name = displayName;
              settings = {
                description = description;
                icon = "prowlarr";
                widget.type = "prowlarr";
              };
            };
            glance = {
              inherit category;
              description = description;
              name = displayName;
              id = name;
              icon = "di:prowlarr";
            };
          };
      }
      // arrlib.arrDbs [name];
  };
}
