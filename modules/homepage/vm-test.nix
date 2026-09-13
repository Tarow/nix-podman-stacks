{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [
    ../authelia/vm-test.nix
    ../docker-socket-proxy/vm-test.nix
  ];
  nps.stacks.homepage = {
    enable = true;
    useSocketProxy = true;
    authSecretFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
  };
}
