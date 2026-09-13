{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
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
