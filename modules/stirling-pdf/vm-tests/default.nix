{
  pkgs,
  dummyClientSecretHash,
  dummySecretFile,
  selfSignedCertDir,
  ...
}: let
  # Stirling-PDF (Spring Boot) resolves Authelia's OIDC
  # issuer at startup, so its JVM needs the test CA in its default trust store.
  truststore =
    pkgs.runCommand "nps-stirling-pdf-truststore" {
      nativeBuildInputs = [pkgs.jdk];
    } ''
      mkdir -p "$out"
      keytool \
        -importcert -noprompt \
        -alias "nps-test-ca" \
        -file "${selfSignedCertDir}/wildcard.crt" \
        -keystore "$out/cacerts" \
        -storepass changeit \
        -storetype JKS
    '';
in {
  imports = [../../authelia/vm-tests/default.nix];
  nps.stacks.stirling-pdf = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
  };

  services.podman.containers.stirling-pdf = {
    volumeMap.npsTestTruststore = "${truststore}/cacerts:/opt/java/openjdk/lib/security/cacerts:ro";
  };
}
