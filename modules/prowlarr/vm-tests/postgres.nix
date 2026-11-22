{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.prowlarr.db = {
    type = "postgres";
    passwordFile = dummySecretFile;
  };
}
