{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.tandoor = {
    enable = true;
    secretKeyFile = dummySecretFile;
    db.passwordFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
    containers.tandoor.extraEnv = {
      SOCIAL_DEFAULT_ACCESS = 1;
      SOCIAL_DEFAULT_GROUP = "user";
    };
  };
}
