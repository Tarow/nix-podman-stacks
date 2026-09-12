{dummySecretFile, ...}: {
  nps.stacks.aiostreams = {
    enable = true;
    secretKeyFile = dummySecretFile;
  };
}
