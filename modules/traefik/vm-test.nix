{
  lib,
  pkgs,
  config,
  ...
}: let
  domain = config.nps.stacks.traefik.domain;
  # Throwaway self-signed wildcard certificate for the test domain.
  # Traefik serves it instead of a Let's Encrypt certificate, which cannot
  # be issued inside a VM. The certificate doubles as its own trust anchor
  # so dependent stacks can validate HTTPS connections from within the test.
  certDir =
    pkgs.runCommand "nps-test-certs" {
      nativeBuildInputs = [pkgs.openssl];
    } ''
      mkdir -p "$out"
      openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout "$out/wildcard.key" \
        -out "$out/wildcard.crt" \
        -days 30 \
        -subj "/CN=*.${domain}" \
        -addext "subjectAltName=DNS:${domain},DNS:*.${domain}" \
        -addext "basicConstraints=critical,CA:TRUE"
    '';
in {
  # Expose the certificate directory so other test modules can mount/trust it.
  _module.args.selfSignedCertDir = certDir;

  nps.stacks.traefik = {
    enable = true;
    domain = lib.mkDefault "example.com";
    # Static file certificate as a replacement for the ACME-resolved wildcard
    # certificate (see the `certificatesResolvers` in the static config).
    dynamicConfig.tls.certificates = [
      {
        certFile = "/etc/traefik/certs/wildcard.crt";
        keyFile = "/etc/traefik/certs/wildcard.key";
      }
    ];
  };

  services.podman.containers.traefik.volumeMap.npsTestCerts = "${certDir}:/etc/traefik/certs:ro";
}
