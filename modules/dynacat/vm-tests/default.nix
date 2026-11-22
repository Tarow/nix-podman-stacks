{pkgs, ...}: let
  # Dynacat expects a base64 encoded 64 byte key on a single line
  secretKeyFile =
    pkgs.runCommand "dynacat-test-secret-key" {
      nativeBuildInputs = [
        pkgs.coreutils
        pkgs.openssl
      ];
    } ''
      openssl rand -base64 64 | tr -d '\n' > "$out"
    '';
in {
  nps.stacks.dynacat = {
    enable = true;
    secretKeyFile = secretKeyFile;
  };
}
