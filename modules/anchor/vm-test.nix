{dummySecretFile, ...}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.anchor = {
    enable = true;
    oidc.enable = true;
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
  };
}
