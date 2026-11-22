{
  selfSignedCertDir,
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: {
  imports = [
    ./default.nix
    ../../authelia/vm-tests/default.nix
  ];
  nps.stacks.dynacat.oidc = {
    enable = true;
    clientSecretFile = dummySecretFile;
    clientSecretHash = dummyClientSecretHash;
  };

  # Dynacat performs OIDC discovery against Authelia over HTTPS on startup and
  # exits when it fails, so trust the test certificate and keep retrying.
  services.podman.containers.dynacat = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
    extraConfig.Unit = {
      StartLimitIntervalSec = 0;
      StartLimitBurst = 30;
    };
  };
}
