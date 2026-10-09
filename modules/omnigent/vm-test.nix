{
  dummySecretFile,
  dummyClientSecretHash,
  selfSignedCertDir,
  ...
}: {
  imports = [
    ../authelia/vm-test.nix
  ];

  nps.stacks.omnigent = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
      cookieSecretFile = dummySecretFile;
    };
  };

  # Omnigent performs the OIDC discovery against Authelia over HTTPS at startup.
  # Trust the self-signed wildcard certificate that Traefik serves in this test.
  services.podman.containers.omnigent = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
  };
}
