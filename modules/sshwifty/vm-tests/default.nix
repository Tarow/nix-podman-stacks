{dummySecretFile, ...}: {
  nps.stacks.sshwifty = {
    enable = true;
    settings = {
      SharedKey = "insecure-test-shared-key";
      Presets = [
        {
          Title = "Host SSH";
          Type = "SSH";
          Host = "host.containers.internal:22";
          Meta = {
            User = "user";
            Encoding = "utf-8";
            "Private Key" = "file:///secrets/private-key";
            Authentication = "Private Key";
          };
        }
      ];
    };
  };

  # Mount the dummy private key into the container so the config's
  # `file:///secrets/private-key` reference resolves.
  services.podman.containers.sshwifty.volumeMap.privateKey = "${dummySecretFile}:/secrets/private-key:ro";
}
