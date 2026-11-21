{...}: {
  nps.stacks.pangolin-newt = {
    enable = true;
    # Dummy credentials; newt retries connecting to the (nonexistent) pangolin
    # server and stays running as a daemon.
    extraEnv = {
      PANGOLIN_ENDPOINT = "ws://10.80.0.1:3080";
      NEWT_ID = "test-newt";
      NEWT_SECRET = "test-secret";
    };
  };
}
