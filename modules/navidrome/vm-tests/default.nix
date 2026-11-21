{...}: {
  nps.stacks.navidrome = {
    enable = true;
    extraEnv = {
      ND_LOGLEVEL = "info";
      ND_ENABLETRANSCODINGCONFIG = true;
    };
  };
}
