{lib, ...}: {
  imports = [./default.nix];
  nps.stacks.shelfmark.useFlaresolverr = lib.mkForce true;
}
