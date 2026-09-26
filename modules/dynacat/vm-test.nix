{
  pkgs,
  selfSignedCertDir,
  dummyClientSecretHash,
  dummySecretFile,
  ...
}: let
  # Dynacat expects a base64 encoded 64 byte key on a single line
  secretKeyFile =
    pkgs.runCommand "dynacat-test-secret-key" {
      nativeBuildInputs = [
        pkgs.coreutils
        pkgs.openssl
      ];
    } ''
      openssl rand -base64 64 | tr -d '\n' > "$out"
    '';
in {
  imports = [
    ../authelia/vm-test.nix
    ../docker-socket-proxy/vm-test.nix
  ];
  nps.stacks.dynacat = {
    enable = true;
    useSocketProxy = true;
    secretKeyFile = secretKeyFile;
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyClientSecretHash;
    };
  };

  # Dynacat performs the OIDC discovery against Authelia over HTTPS on startup and
  # exits when it fails, so it has to trust the self-signed wildcard certificate
  # that Traefik serves in this test and keep retrying until Authelia is up.
  services.podman.containers.dynacat = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
    extraConfig.Unit = {
      StartLimitIntervalSec = 0;
      StartLimitBurst = 30;
    };
  };
}
