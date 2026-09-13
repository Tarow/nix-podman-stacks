{
  pkgs,
  dummyHash,
  dummySecretFile,
  selfSignedCertDir,
  ...
}: let
  # Komga (Spring Boot) resolves Authelia's OIDC
  # issuer at startup, so its JVM needs the test CA in a trust store to validate
  # `https://authelia.example.com/.well-known/openid-configuration`.
  truststore =
    pkgs.runCommand "nps-komga-truststore" {
      nativeBuildInputs = [pkgs.jdk];
    } ''
      mkdir -p "$out"
      keytool \
        -importcert -noprompt \
        -alias "nps-test-ca" \
        -file "${selfSignedCertDir}/wildcard.crt" \
        -keystore "$out/truststore.p12" \
        -storepass changeit \
        -storetype PKCS12
    '';
in {
  imports = [../authelia/vm-test.nix];
  nps.stacks.komga = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
  };

  services.podman.containers.komga = {
    extraEnv.JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=/etc/ssl/nps-truststore.p12 -Djavax.net.ssl.trustStorePassword=changeit -Djavax.net.ssl.trustStoreType=PKCS12";
    volumeMap.npsTestTruststore = "${truststore}/truststore.p12:/etc/ssl/nps-truststore.p12:ro";
  };
}
