{...}: {
  nps.stacks.monitoring = {
    enable = true;
    alloy.enable = false;
    loki.enable = false;
    podmanExporter.enable = false;
  };
}
