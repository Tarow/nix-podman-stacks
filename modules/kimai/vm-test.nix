{
  dummyEmail,
  dummySecretFile,
  ...
}: {
  nps.stacks.kimai = {
    enable = true;
    adminEmail = dummyEmail;
    adminPasswordFile = dummySecretFile;
    db = {
      userPasswordFile = dummySecretFile;
      rootPasswordFile = dummySecretFile;
    };
  };
}
