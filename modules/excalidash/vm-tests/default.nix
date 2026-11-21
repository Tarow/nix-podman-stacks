{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.excalidash = {
    enable = true;
    jwtSecretFile = dummySecretFile;
    csrfSecretFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
  };
}
