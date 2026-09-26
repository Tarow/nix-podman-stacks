{
  config,
  lib,
  ...
}: let
  name = "watchstate";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Media & Downloads";
  description = "Play State Synchronization";
  displayName = "WatchState";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/arabcoders/watchstate:v1.10.6";
      user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
      volumeMap.data = "${storage}/data:/config";

      port = 8080;
      traefik.name = name;
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "sh:watchstate";
      };
    };
  };
}
