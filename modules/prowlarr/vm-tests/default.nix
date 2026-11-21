{dummySecretFile, ...}: {
  nps.stacks.prowlarr = {
    enable = true;
    db = {
      type = "postgres";
      passwordFile = dummySecretFile;
    };
    extraEnv."PROWLARR__AUTH__APIKEY".fromFile = dummySecretFile;
  };
}
