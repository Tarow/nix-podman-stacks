{dummySecretFile, ...}: {
  nps.stacks.super-productivity = {
    enable = true;
    enableSync = true;
    jwtSecretFile = dummySecretFile;
    db.passwordFile = dummySecretFile;
    smtp = {
      host = "localhost";
      user = "test";
      passwordFile = dummySecretFile;
      from = "test@localhost";
    };
  };
}
