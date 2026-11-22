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
  nps.stacks.forgejo.oidc = {
    enable = true;
    clientSecretFile = dummySecretFile;
    clientSecretHash = dummyClientSecretHash;
  };
  services.podman.containers.forgejo = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
  };
}
