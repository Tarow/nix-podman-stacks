{...}: {
  imports = [../../socket-proxy/vm-tests/default.nix];
  nps.stacks.dozzle = {
    enable = true;
    useSocketProxy = true;
  };
}
