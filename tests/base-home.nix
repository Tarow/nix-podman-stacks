# Central home-manager-side configuration for VM integration tests.
# Provides the base `nps` settings and dummy secrets. The modules from
# `modules/module_list.nix` are imported via `self.homeModules.nps` in
# `tests/base-config.nix`.
{pkgs, ...}: {
  home = {
    username = "ci";
    homeDirectory = "/home/ci";
    stateVersion = "26.05";
  };

  # Dummy secrets shared by all `vm-test.nix` files.
  # Never use real secrets here.
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
