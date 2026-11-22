{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [
    ./default.nix
    ../../authelia/vm-tests/default.nix
  ];
  nps.stacks.homelable.oidc = {
    enable = true;
    clientSecretFile = dummySecretFile;
    clientSecretHash = dummyClientSecretHash;
  };
}
