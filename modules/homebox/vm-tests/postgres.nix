{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.homebox.db = {
    type = "postgres";
    passwordFile = dummySecretFile;
  };
}
