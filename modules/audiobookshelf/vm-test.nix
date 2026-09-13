{dummyClientSecretHash, ...}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.audiobookshelf = {
    enable = true;
    oidc = {
      registerClient = true;
      clientSecretHash = dummyClientSecretHash;
    };
  };
}
