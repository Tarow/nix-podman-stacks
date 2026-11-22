{...}: {
  imports = [
    ./default.nix
    ../../socket-proxy/vm-tests/default.nix
  ];
  nps.stacks.pangolin-newt.useSocketProxy = true;
}
