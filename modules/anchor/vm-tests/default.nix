{dummySecretFile, ...}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.anchor = {
    enable = true;
    oidc.enable = true;
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
  };
}
