{
  dummySecretFile,
  dummyClientSecretHash,
  dummyEmail,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.adventurelog = {
    enable = true;
    secretKeyFile = dummySecretFile;
    db.passwordFile = dummySecretFile;
    adminProvisioning = {
      username = "admin";
      email = dummyEmail;
      passwordFile = dummySecretFile;
    };
    oidc = {
      registerClient = true;
      clientSecretHash = dummyClientSecretHash;
    };
  };
}
