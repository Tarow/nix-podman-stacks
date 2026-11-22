{
  dummyEmail,
  dummySecretFile,
  dummyUser,
  ...
}: {
  nps.stacks.paperless = {
    enable = true;
    adminProvisioning = {
      username = dummyUser;
      email = dummyEmail;
      passwordFile = dummySecretFile;
    };
    secretKeyFile = dummySecretFile;
    db.passwordFile = dummySecretFile;
  };
}
