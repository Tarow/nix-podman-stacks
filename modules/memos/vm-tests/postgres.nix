{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.memos.db = {
    type = "postgres";
    passwordFile = dummySecretFile;
  };
}
