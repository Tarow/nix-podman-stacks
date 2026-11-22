{dummySecretFile, ...}: {
  imports = [./default.nix];
  nps.stacks.homelable.mcp = {
    enable = true;
    apiKeyFile = dummySecretFile;
    serviceKeyFile = dummySecretFile;
  };
}
