{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [
    ./default.nix
    ../../authelia/vm-tests/default.nix
  ];
  nps.stacks.bambuddy.oidc = {
    enable = true;
    clientSecretFile = dummySecretFile;
    clientSecretHash = dummyClientSecretHash;
  };
}
