{
  dummySecretFile,
  dummyClientSecretHash,
  pkgs,
  lib,
  selfSignedCertDir,
  ...
}: {
  imports = [../authelia/vm-test.nix];

  nps.stacks.netbird-management = {
    enable = true;
    authSecretFile = dummySecretFile;
    storeEncryptionKeyFile = pkgs.writeText "netbird-encryption-key" "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=";
    adminProvisioning = {
      email = "admin@example.com";
      passwordFile = dummySecretFile;
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
  };

  services.podman.containers.netbird-management-server = {
    environment.SSL_CERT_FILE = "/etc/ssl/certs/nps-test-ca.crt";
    volumeMap.npsTestCa = "${selfSignedCertDir}/wildcard.crt:/etc/ssl/certs/nps-test-ca.crt:ro";
    extraConfig.Container.AddHost = "authelia.example.com:host-gateway";
    # The integration test verifies container composition; connector validation
    # requires a public issuer reachable by the NetBird server.
    extraConfig.Service.ExecStartPost = lib.mkForce [];
  };
}
