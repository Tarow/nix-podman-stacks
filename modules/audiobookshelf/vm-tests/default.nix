{dummyClientSecretHash, ...}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.audiobookshelf = {
    enable = true;
    oidc = {
      registerClient = true;
      clientSecretHash = dummyClientSecretHash;
    };
  };
}
