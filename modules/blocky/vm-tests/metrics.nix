{...}: {
  imports = [./default.nix];
  nps.stacks.blocky = {
    enableGrafanaDashboard = true;
    enablePrometheusExport = true;
  };
}
