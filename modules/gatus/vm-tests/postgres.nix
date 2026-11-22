{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.gatus.db = {
    type = "postgres";
    passwordFile = dummySecretFile;
  };
}
