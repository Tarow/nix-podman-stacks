{dummySecretFile, ...}: {
  nps.stacks.searxng = {
    enable = true;
    secretKeyFile = dummySecretFile;
    settings.engines = [
      {
        name = "dummy.online";
        engine = "dummy";
      }
    ];
  };
}
