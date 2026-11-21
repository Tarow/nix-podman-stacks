{...}: {
  imports = [../../socket-proxy/vm-tests/default.nix];
  nps.stacks.crowdsec = {
    enable = true;
    useSocketProxy = true;
    enableGrafanaDashboard = true;
    enablePrometheusExport = true;
  };
}
