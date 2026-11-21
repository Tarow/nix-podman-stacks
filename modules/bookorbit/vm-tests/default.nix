{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];

  nps.stacks.bookorbit = {
    enable = true;
    jwtSecretFile = dummySecretFile;
    setupBootstrapTokenFile = dummySecretFile;
    db.passwordFile = dummySecretFile;
    oidc = {
      registerClient = true;
      clientSecretHash = dummyClientSecretHash;
    };
    tts.enable = true;
  };
}
