{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [
    ../../authelia/vm-tests/default.nix
    ../../socket-proxy/vm-tests/default.nix
  ];
  nps.stacks.homepage = {
    enable = true;
    useSocketProxy = true;
    authSecretFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
  };
}
