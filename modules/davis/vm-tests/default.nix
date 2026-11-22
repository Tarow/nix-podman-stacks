{dummySecretFile, ...}: {
  nps.stacks.davis = {
    enable = true;
    adminPasswordFile = dummySecretFile;
    db.type = "sqlite";
  };
}
