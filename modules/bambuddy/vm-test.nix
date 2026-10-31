{
  pkgs,
  dummySecretFile,
  dummyClientSecretHash,
  ...
}: {
  imports = [../authelia/vm-test.nix];

  nps.stacks.bambuddy = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
    orcaSlicer.enable = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
    bambuStudio.enable = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
    virtualPrinter.enable = true;
  };
}
