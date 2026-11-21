{dummySecretFile, ...}: {
  nps.stacks.microbin = {
    enable = true;
    extraEnv = {
      MICROBIN_ADMIN_USERNAME = "admin";
      MICROBIN_ADMIN_PASSWORD.fromFile = dummySecretFile;
      MICROBIN_UPLOADER_PASSWORD.fromFile = dummySecretFile;
      MICROBIN_ENABLE_DISCORD_BUTTON = false;
    };
  };
}
