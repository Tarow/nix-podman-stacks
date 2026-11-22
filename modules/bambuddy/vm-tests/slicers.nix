{pkgs, ...}: {
  imports = [./default.nix];
  nps.stacks.bambuddy = {
    orcaSlicer.enable = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
    bambuStudio.enable = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  };
}
