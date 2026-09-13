{
  config,
  lib,
  dummyHash,
  dummySecretFile,
  selfSignedCertDir,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.filebrowser-quantum = {
    enable = true;
    mounts = {
      "${config.nps.externalStorageBaseDir}/hdd" = {
        path = "/hdd";
        name = "hdd";
        config.denyByDefault = true;
      };
    };
    oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
    settings.auth.methods.password.enabled = false;
  };

  services.podman.containers.filebrowser-quantum = {
    extraEnv.SSL_CERT_FILE = "/etc/ssl/certs/nps-test/wildcard.crt";
    volumeMap.npsTestCert = "${selfSignedCertDir}:/etc/ssl/certs/nps-test:ro";
    extraPodmanArgs = [
      "--add-host=${config.nps.stacks.traefik.domain}:${config.nps.stacks.traefik.ip4}"
    ];
  };
}
