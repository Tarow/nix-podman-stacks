{dummySecretFile, ...}: {
  nps.stacks.wg-easy = {
    enable = true;
    adminUsername = "admin";
    adminPasswordFile = dummySecretFile;
    host = "192.168.1.1";
    port = 51820;
  };
}
