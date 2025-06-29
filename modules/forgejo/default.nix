{
  config,
  lib,
  ...
}: let
  name = "forgejo";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix lib name [name];

  options.tarow.podman.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "codeberg.org/forgejo/forgejo:latest";
      volumes = [
        "${storage}/data:/data"
      ];
      ports = ["222:22"];
      environment = {
        USER_UID = config.tarow.podman.defaultUid;
        USER_GID = config.tarow.podman.defaultGid;
      };

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
