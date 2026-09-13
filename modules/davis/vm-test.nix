{dummySecretFile, ...}: {
  imports = [
    ../lldap/vm-test.nix
    ../traefik/vm-test.nix
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
