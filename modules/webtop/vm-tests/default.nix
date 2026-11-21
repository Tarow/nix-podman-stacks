{
  dummySecretFile,
  dummyUser,
  ...
}: {
  nps.stacks.webtop = {
    enable = true;
    username = dummyUser;
    passwordFile = dummySecretFile;
  };
}
