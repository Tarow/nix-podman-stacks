{lib, ...}: {
  nps.stacks.frigate = {
    enable = true;
    containers.frigate.devices = lib.mkForce [];
  };
}
