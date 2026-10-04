{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];

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
