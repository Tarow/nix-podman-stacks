{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.guacamole.db = {
    enable = true;
    passwordFile = dummySecretFile;
  };
}
