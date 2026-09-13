{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
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
      clientSecretHash = dummyHash;
    };
    db = {
      userPasswordFile = dummySecretFile;
      rootPasswordFile = dummySecretFile;
    };
  };
}
