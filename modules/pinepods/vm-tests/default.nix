{
  dummyClientSecretHash,
  dummyEmail,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.pinepods = {
    enable = true;
    db.passwordFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
    adminProvisioning = {
      enable = true;
      email = dummyEmail;
      passwordFile = dummySecretFile;
    };
  };
}
