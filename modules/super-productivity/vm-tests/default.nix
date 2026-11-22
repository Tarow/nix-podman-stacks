{...}: {
  imports = [../../traefik/vm-tests/default.nix];

  nps.stacks.super-productivity.enable = true;
}
