{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.paperless.ftp = {
    enable = true;
    passwordFile = dummySecretFile;
  };
}
