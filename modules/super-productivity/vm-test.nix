{dummySecretFile, ...}: {
  # PUBLIC_URL needs to be https://...
  imports = [../traefik/vm-test.nix];

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
