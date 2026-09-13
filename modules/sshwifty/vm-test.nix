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
            "Private Key" = "file://${dummySecretFile}";
            Authentication = "Private Key";
          };
        }
      ];
    };
  };
}
