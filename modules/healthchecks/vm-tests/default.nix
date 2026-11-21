{
  dummyEmail,
  dummySecretFile,
  ...
}: {
  nps.stacks.healthchecks = {
    enable = true;
    secretKeyFile = dummySecretFile;
    superUserEmail = dummyEmail;
    superUserPasswordFile = dummySecretFile;
  };
}
