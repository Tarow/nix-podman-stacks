{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.sparky-fitness = {
    enable = true;
    betterAuthSecretFile = dummySecretFile;
    apiEncryptionKeyFile = dummySecretFile;
    db.passwordFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
  };
}
