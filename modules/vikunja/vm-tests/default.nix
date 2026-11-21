{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.vikunja = {
    enable = true;
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
    jwtSecretFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
    settings = {
      service.enableregistration = false;
      auth.local.enabled = false;
    };
  };
}
