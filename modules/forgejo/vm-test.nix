{
  dummyHash,
  dummySecretFile,
  selfSignedCertDir,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.forgejo = {
    enable = true;
    lfsJwtSecretFile = dummySecretFile;
    secretKeyFile = dummySecretFile;
    internalTokenFile = dummySecretFile;
    jwtSecretFile = dummySecretFile;
    adminProvisioning = {
      username = "forgejo";
      email = "admin@test.com";
      passwordFile = dummySecretFile;
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
  };

  services.podman.containers.forgejo = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
  };
}
