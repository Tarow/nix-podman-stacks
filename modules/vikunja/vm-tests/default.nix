{dummySecretFile, ...}: {
  nps.stacks.vikunja = {
    enable = true;
    jwtSecretFile = dummySecretFile;
  };
}
