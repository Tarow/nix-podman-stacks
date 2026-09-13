{
  dummyEmail,
  dummySecretFile,
  ...
}: {
  imports = [../authelia/vm-test.nix];
  nps.stacks.hortusfox = {
    enable = true;
    containers.hortusfox.forwardAuth = {
      enable = true;
      rules = [
        {
          policy = "one_factor";
        }
      ];
    };
    db = {
      userPasswordFile = dummySecretFile;
      rootPasswordFile = dummySecretFile;
    };
    adminEmail = dummyEmail;
    extraEnv = {
      PROXY_ENABLE = true;
      PROXY_HEADER_EMAIL = "Remote-Email";
      PROXY_HEADER_USERNAME = "Remote-User";
      PROXY_AUTO_SIGNUP = true;
      PROXY_HIDE_LOGOUT = true;
    };
  };
}
