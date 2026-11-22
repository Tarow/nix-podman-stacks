{lib, ...}: {
  imports = [./default.nix];
  npsTests.memorySize = 4096;
  nps.stacks.streaming = {
    useQbittorrent = lib.mkForce true;
    useProwlarr = lib.mkForce true;
    useSabnzbd = lib.mkForce true;
  };
  nps.stacks.qbittorrent.gluetun.enable = false;
}
