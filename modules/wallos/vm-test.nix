{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.wallos = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
  };
}
