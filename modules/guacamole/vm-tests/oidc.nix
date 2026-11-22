{...}: {
  imports = [
    ./db.nix
    ../../authelia/vm-tests/default.nix
  ];
  nps.stacks.guacamole.oidc.enable = true;
}
