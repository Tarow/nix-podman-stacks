{
  lib,
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.immich = {
    enable = true;
    containers.immich.devices = lib.mkForce [];
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
    db.passwordFile = dummySecretFile;
  };
}
