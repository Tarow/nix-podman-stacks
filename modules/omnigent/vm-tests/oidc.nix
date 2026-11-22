{
  dummyClientSecretHash,
  dummySecretFile,
  selfSignedCertDir,
  ...
}: {
  imports = [
    ./default.nix
    ../../authelia/vm-tests/default.nix
  ];
  nps.stacks.omnigent.oidc = {
    enable = true;
    clientSecretFile = dummySecretFile;
    clientSecretHash = dummyClientSecretHash;
    cookieSecretFile = dummySecretFile;
  };

  services.podman.containers.omnigent = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
  };
}
