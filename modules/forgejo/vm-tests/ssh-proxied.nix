{...}: {
  imports = [
    ./default.nix
    ../../traefik/vm-tests/default.nix
  ];
  nps.stacks.forgejo.ssh.proxied = true;
}
