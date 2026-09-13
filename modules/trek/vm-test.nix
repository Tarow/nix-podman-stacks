{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.trek = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
  };
}
