{dummySecretFile, ...}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.grimmory = {
    enable = true;
    oidc.registerClient = true;
    db = {
      userPasswordFile = dummySecretFile;
      rootPasswordFile = dummySecretFile;
    };
  };
}
