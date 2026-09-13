{dummySecretFile, ...}: {
  nps.stacks.spliit = {
    enable = true;
    db.passwordFile = dummySecretFile;
  };
}
