{
  lib,
  config,
  ...
}: let
  dockdnsEnabled = config.nps.stacks.dockdns.enable;
  traefikEnabled = config.nps.stacks.traefik.enable;
in {
  # If a container is exposed, create a record for it
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
      config = lib.mkIf (dockdnsEnabled && traefikEnabled && config.expose) {
        labels."dockdns.name" = config.traefik.serviceHost;
      };
    }));
  };
}
