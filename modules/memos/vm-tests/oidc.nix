{dummyClientSecretHash, ...}: {
  imports = [
    ./default.nix
    ../../authelia/vm-tests/default.nix
  ];
  nps.stacks.memos.oidc = {
    registerClient = true;
    clientSecretHash = dummyClientSecretHash;
  };
}
