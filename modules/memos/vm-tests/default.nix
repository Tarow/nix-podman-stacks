{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.memos = {
    enable = true;
    oidc = {
      registerClient = true;
      clientSecretHash = dummyClientSecretHash;
    };
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
  };
}
