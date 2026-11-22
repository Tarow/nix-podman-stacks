{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.forgejo.db = {
    type = "postgres";
    passwordFile = dummySecretFile;
  };
}
