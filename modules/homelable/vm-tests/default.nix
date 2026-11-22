{dummySecretFile, ...}: {
  nps.stacks.homelable = {
    enable = true;
    secretKeyFile = dummySecretFile;
    auth.passwordHashFile = dummySecretFile;
  };
}
