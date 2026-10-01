{...}: {
  imports = [../socket-proxy/vm-test.nix];
  nps.stacks.dozzle = {
    enable = true;
    useSocketProxy = true;
  };
}
