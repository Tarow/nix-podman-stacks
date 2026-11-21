{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.leantime = {
    enable = true;
    sessionPasswordFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
    db = {
      userPasswordFile = dummySecretFile;
      rootPasswordFile = dummySecretFile;
    };
  };
}
