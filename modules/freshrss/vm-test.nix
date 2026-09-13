{
  dummyHash,
  dummyEmail,
  dummySecretFile,
  dummyUser,
  ...
}: {
  imports = [../authelia/vm-test.nix];
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
      clientSecretHash = dummyHash;
      cryptoKeyFile = "insecure-test-crypto-key";
    };
  };
}
