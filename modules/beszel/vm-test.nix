{
  config,
  pkgs,
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: let
  sshKeys =
    pkgs.runCommand "beszel-test-ssh-keys" {
      nativeBuildInputs = [pkgs.openssh];
    } ''
      mkdir -p $out
      ssh-keygen -q -t ed25519 -N "" -C "beszel-test" -f $out/id_ed25519
    '';
in {
  imports = [
    ../authelia/vm-test.nix
    ../docker-socket-proxy/vm-test.nix
  ];
  nps.stacks.beszel = {
    enable = true;
    ed25519PrivateKeyFile = "${sshKeys}/id_ed25519";
    ed25519PublicKeyFile = "${sshKeys}/id_ed25519.pub";
    tokenFile = dummySecretFile;
    adminProvisioning = {
      email = "admin@admin.com";
      passwordFile = dummySecretFile;
    };
    oidc = {
      registerClient = true;
      clientSecretHash = dummyClientSecretHash;
    };
    useSocketProxy = true;
  };
}
