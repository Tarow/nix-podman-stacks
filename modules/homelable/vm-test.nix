{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.homelable = {
    enable = true;
    secretKeyFile = dummySecretFile;
    mcp = {
      enable = true;
      apiKeyFile = dummySecretFile;
      serviceKeyFile = dummySecretFile;
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
  };
}
