{
  lib,
  dummySecretFile,
  ...
}: {
  imports = [./default.nix];
  nps.stacks.shelfmark = {
    useProwlarr = lib.mkForce true;
    extraEnv.PROWLARR_API_KEY.fromFile = dummySecretFile;
  };
}
