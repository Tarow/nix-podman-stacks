{
  lib,
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  # immich runs server + microservices + machine-learning + postgres + redis
  # plus the auth stack - the default 2 GiB VM OOMs.
  npsTests.memorySize = 4096;
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
