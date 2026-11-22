{
  imports = [
    ./default.nix
    ../../lldap/vm-tests/default.nix
    ../../traefik/vm-tests/default.nix
  ];
  nps.stacks.davis.enableLdapAuth = true;
}
