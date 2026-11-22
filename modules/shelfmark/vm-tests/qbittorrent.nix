{lib, ...}: {
  imports = [./default.nix];
  nps.stacks.shelfmark.useQbittorrent = lib.mkForce true;
  nps.stacks.qbittorrent.gluetun.enable = false;
}
