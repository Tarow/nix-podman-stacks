{
  config,
  dummyClientSecretHash,
  dummySecretFile,
  selfSignedCertDir,
  ...
}: {
  imports = [
    ./default.nix
    ../../authelia/vm-tests/default.nix
  ];
  nps.stacks.gatus = {
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

  services.podman.containers.gatus = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
  };
}
