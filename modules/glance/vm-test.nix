{...}: {
  imports = [../docker-socket-proxy/vm-test.nix];
  nps.stacks.glance = {
    enable = true;
    useSocketProxy = true;
  };
}
