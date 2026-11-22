{...}: {
  imports = [./default.nix];
  nps.stacks.crowdsec = {
    enableGrafanaDashboard = true;
    enablePrometheusExport = true;
  };
}
