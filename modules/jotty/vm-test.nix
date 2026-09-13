{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.jotty = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
  };
}
