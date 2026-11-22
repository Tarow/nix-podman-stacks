{dummySecretFile, ...}: {
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
  };
}
