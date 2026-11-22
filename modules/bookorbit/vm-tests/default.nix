{dummySecretFile, ...}: {
  nps.stacks.bookorbit = {
    enable = true;
    jwtSecretFile = dummySecretFile;
    setupBootstrapTokenFile = dummySecretFile;
    db.passwordFile = dummySecretFile;
  };
}
