{dummySecretFile, ...}: {
  nps.stacks.homebox = {
    enable = true;
    apiKeyPepperFile = dummySecretFile;
  };
}
