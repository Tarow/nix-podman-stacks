{
  dummyHash,
  dummyEmail,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.pinepods = {
    enable = true;
    db.passwordFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
    adminProvisioning = {
      enable = true;
      email = dummyEmail;
      passwordFile = dummySecretFile;
    };
  };
}
