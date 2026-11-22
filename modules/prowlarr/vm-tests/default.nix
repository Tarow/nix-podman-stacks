{dummySecretFile, ...}: {
  nps.stacks.prowlarr = {
    enable = true;
    extraEnv."PROWLARR__AUTH__APIKEY".fromFile = dummySecretFile;
  };
}
