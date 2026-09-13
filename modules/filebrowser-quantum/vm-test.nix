{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.filebrowser-quantum = {
    enable = true;
    mounts = {
      "/mnt/hdd" = {
        path = "/hdd";
        name = "hdd";
        config.denyByDefault = true;
      };
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
    settings.auth.methods.password.enabled = false;
  };
}
