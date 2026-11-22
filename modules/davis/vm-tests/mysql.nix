{
  lib,
  dummySecretFile,
  ...
}: {
  imports = [./default.nix];
  nps.stacks.davis.db = {
    type = lib.mkForce "mysql";
    userPasswordFile = dummySecretFile;
    rootPasswordFile = dummySecretFile;
  };
}
