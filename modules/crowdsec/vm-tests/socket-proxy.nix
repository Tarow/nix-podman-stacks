{...}: {
  imports = [
    ./default.nix
    ../../socket-proxy/vm-tests/default.nix
  ];
  nps.stacks.crowdsec.useSocketProxy = true;
}
