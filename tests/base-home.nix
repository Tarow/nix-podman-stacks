# Base home-manager settings for VM integration tests.
{
  config,
  lib,
  ...
}: {
  options.npsTests.memorySize = lib.mkOption {
    type = lib.types.int;
    default = 2048;
    description = "Memory size of the integration test VM in MiB. Override per stack in its vm-tests/default.nix or scenario file.";
  };

  config = {
    home = {
      username = "ci";
      homeDirectory = "/home/ci";
      stateVersion = "26.05";
    };

    nps = {
      # mkDefault so a tested config can set its own values
      hostUid = lib.mkDefault 1000;
      storageBaseDir = lib.mkDefault "${config.home.homeDirectory}/stacks";
      externalStorageBaseDir = lib.mkDefault "${config.home.homeDirectory}/external";
      defaultTz = lib.mkDefault "UTC";
      hostIP4Address = lib.mkDefault "192.168.1.1";
    };
  };
}
