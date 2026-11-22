{lib, ...}: {
  imports = [../../traefik/vm-tests/default.nix];
  npsTests.memorySize = 4096;
  nps.stacks.streaming = {
    enable = true;
    useQbittorrent = true;
    useProwlarr = true;
    useSabnzbd = true;
  };
  nps.stacks.qbittorrent.gluetun.enable = false;

  # No GPU in the test VM.
  services.podman.containers.jellyfin.devices = lib.mkForce [];
}
