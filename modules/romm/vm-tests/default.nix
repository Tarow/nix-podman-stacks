{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.romm = {
    enable = true;
    authSecretKeyFile = dummySecretFile;
    extraEnv = {
      IGDB_CLIENT_ID.fromFile = dummySecretFile;
      IGDB_CLIENT_SECRET.fromFile = dummySecretFile;
    };
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
