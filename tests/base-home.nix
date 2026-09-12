# Base home-manager settings for VM integration tests.
{pkgs, ...}: {
  home = {
    username = "ci";
    homeDirectory = "/home/ci";
    stateVersion = "26.05";
  };

  # Dummy secrets (never use real ones here)
  _module.args = {
    dummySecretFile = "${pkgs.writeText "dummy-secret" "insecure_secret"}";
    dummyHash = "$argon2id$v=19$m=65536,t=3,p=4$8USywQgWNhOf4drzlVTieA$Rm8SlHy+ipThtIa/6nMMir2QkoXESCr4uCB2aAdvlmo";
  };

  nps = {
    hostUid = 1000;
    storageBaseDir = "/home/ci/stacks";
    externalStorageBaseDir = "/mnt/media";
    defaultTz = "UTC";
    hostIP4Address = "192.168.178.2";
  };
}
