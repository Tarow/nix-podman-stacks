{dummyClientSecretHash, ...}: {
  imports = [
    ./default.nix
    ../../authelia/vm-tests/default.nix
  ];
  nps.stacks.bookorbit.oidc = {
    registerClient = true;
    clientSecretHash = dummyClientSecretHash;
  };
}
