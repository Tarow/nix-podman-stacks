{dummySecretFile, ...}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.grimmory = {
    enable = true;
    oidc.registerClient = true;
    db = {
      userPasswordFile = dummySecretFile;
      rootPasswordFile = dummySecretFile;
    };
  };
}
