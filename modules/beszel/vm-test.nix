{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [
    ../authelia/vm-test.nix
    ../docker-socket-proxy/vm-test.nix
  ];
  nps.stacks.beszel = {
    enable = true;
    ed25519PrivateKeyFile = dummySecretFile;
    ed25519PublicKeyFile = dummySecretFile;
    tokenFile = dummySecretFile;
    adminProvisioning = {
      email = "admin@admin.com";
      passwordFile = dummySecretFile;
    };
    oidc = {
      registerClient = true;
      clientSecretHash = dummyClientSecretHash;
    };
    useSocketProxy = true;
  };
}
