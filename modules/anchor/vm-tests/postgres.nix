{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.anchor.db = {
    type = "postgres";
    passwordFile = dummySecretFile;
  };
}
