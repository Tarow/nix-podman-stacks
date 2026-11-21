{dummySecretFile, ...}: {
  imports = [
    ../../lldap/vm-tests/default.nix
    ../../traefik/vm-tests/default.nix
  ];
  nps.stacks.davis = {
    enable = true;
    adminPasswordFile = dummySecretFile;
    enableLdapAuth = true;
    db = {
      type = "mysql";
      userPasswordFile = dummySecretFile;
      rootPasswordFile = dummySecretFile;
    };
  };
}
