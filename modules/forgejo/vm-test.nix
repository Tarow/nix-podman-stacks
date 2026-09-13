{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.forgejo = {
    enable = true;
    lfsJwtSecretFile = dummySecretFile;
    secretKeyFile = dummySecretFile;
    internalTokenFile = dummySecretFile;
    jwtSecretFile = dummySecretFile;
    adminProvisioning = {
      username = "forgejo";
      email = "admin@test.com";
      passwordFile = dummySecretFile;
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
  };
}
