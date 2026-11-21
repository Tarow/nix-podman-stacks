{
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.shelfmark = {
    enable = true;
    useProwlarr = true;
    useQbittorrent = false;
    extraEnv.PROWLARR_API_KEY.fromFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
  };
}
