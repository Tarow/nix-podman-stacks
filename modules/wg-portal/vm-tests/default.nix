{dummySecretFile, ...}: {
  nps.stacks.wg-portal = {
    enable = true;
    port = 51820;
    settings.core.admin = {
      username = "admin";
      password = "\${ADMIN_PASSWORD}";
    };
    extraEnv.ADMIN_PASSWORD.fromFile = dummySecretFile;
  };
}
