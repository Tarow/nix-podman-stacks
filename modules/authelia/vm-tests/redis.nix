{...}: {
  imports = [./default.nix];
  nps.stacks.authelia.sessionProvider = "redis";
}
