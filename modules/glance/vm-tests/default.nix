{...}: {
  imports = [../../socket-proxy/vm-tests/default.nix];
  nps.stacks.glance = {
    enable = true;
    useSocketProxy = true;
  };
}
