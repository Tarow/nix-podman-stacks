{dummySecretFile, ...}: {
  nps.stacks.bytestash = {
    enable = true;
    jwtSecretFile = dummySecretFile;
    extraEnv = {
      ALLOW_NEW_ACCOUNTS = false;
      DISABLE_INTERNAL_ACCOUNTS = false;
    };
  };
}
