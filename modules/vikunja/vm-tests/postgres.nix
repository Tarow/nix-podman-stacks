{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.vikunja.db = {
    type = "postgres";
    passwordFile = dummySecretFile;
  };
}
