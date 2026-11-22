{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.super-productivity = {
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
