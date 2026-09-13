{
  dummyHash,
  dummySecretFile,
  selfSignedCertDir,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.kitchenowl = {
    enable = true;
    jwtSecretFile = dummySecretFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
  };

  # Kitchenowl's Python backend fetches Authelia's
  # `.well-known/openid-configuration` over HTTPS at startup. Trust the test's
  # self-signed wildcard certificate (Python `requests` uses REQUESTS_CA_BUNDLE,
  # while `ssl.create_default_context` honours SSL_CERT_FILE).
  services.podman.containers.kitchenowl-backend = {
    extraEnv = {
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/nps-test/wildcard.crt";
      CURL_CA_BUNDLE = "/etc/ssl/certs/nps-test/wildcard.crt";
      SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    };
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
  };
}
