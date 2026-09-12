{
  config,
  dummySecretFile,
  dummyClientSecretHash,
  selfSignedCertDir,
  ...
}: {
  imports = [
    ../authelia/vm-test.nix
  ];

  nps.stacks.gatus = {
    enable = true;
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
    settings.endpoints = [
      {
        name = "Authelia";
        url = config.nps.containers.authelia.traefik.serviceUrl;
      }
    ];
  };

  # Gatus performs the OIDC discovery against Authelia over HTTPS at startup.
  # Trust the self-signed wildcard certificate that Traefik serves in this test.
  services.podman.containers.gatus = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
  };
}
