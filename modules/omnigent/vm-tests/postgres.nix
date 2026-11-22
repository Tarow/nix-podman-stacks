{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.omnigent.db = {
    type = "postgres";
    passwordFile = dummySecretFile;
  };
}
