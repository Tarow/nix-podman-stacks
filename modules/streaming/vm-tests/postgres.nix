{
  lib,
  dummySecretFile,
  ...
}: {
  imports = [./default.nix];
  npsTests.memorySize = 4096;
  nps.stacks.streaming = lib.genAttrs ["sonarr" "radarr" "bazarr"] (_: {
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
  });
}
