{...}: {
  imports = [../docker-socket-proxy/vm-test.nix];
  nps.stacks.crowdsec = {
    enable = true;
    useSocketProxy = true;
    enableGrafanaDashboard = true;
    enablePrometheusExport = true;
  };
}
