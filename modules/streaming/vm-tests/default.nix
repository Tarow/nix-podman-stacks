{lib, ...}: {
  nps.stacks.streaming = {
    enable = true;
    useQbittorrent = false;
    useProwlarr = false;
    useSabnzbd = false;
  };

  # No GPU in the test VM.
  services.podman.containers.jellyfin.devices = lib.mkForce [];
}
