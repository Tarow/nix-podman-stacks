{
  dummySecretFile,
  dummyEmail,
  ...
}: {
  nps.stacks.lldap = {
    enable = true;
    baseDn = "DC=example,DC=com";
    jwtSecretFile = dummySecretFile;
    keySeedFile = dummySecretFile;
    adminPasswordFile = dummySecretFile;
    bootstrap = {
      cleanUp = true;
      users.test = {
        email = dummyEmail;
        password_file = dummySecretFile;
      };
    };
  };
}
