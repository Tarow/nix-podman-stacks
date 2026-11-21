{
  dummyClientSecretHash,
  dummyEmail,
  dummySecretFile,
  dummyUser,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.freshrss = {
    enable = true;
    adminProvisioning = {
      enable = true;
      username = dummyUser;
      email = dummyEmail;
      passwordFile = dummySecretFile;
      apiPasswordFile = dummySecretFile;
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
      cryptoKeyFile = "insecure-test-crypto-key";
    };
  };
}
