{lib, ...}: {
  imports = [
    ./default.nix
    ../../socket-proxy/vm-tests/default.nix
    ../../ntfy/vm-tests/default.nix
  ];
  nps.stacks.monitoring = {
    alloy = {
      enable = lib.mkForce true;
      useSocketProxy = true;
    };
    loki.enable = lib.mkForce true;
    podmanExporter.enable = lib.mkForce true;
    prometheus.rules.groups = [
      {
        name = "resource.usage";
        rules = [
          {
            alert = "HighCpuUsage";
            expr = ''
              100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90'';
            for = "20m";
            labels = {severity = "warning";};
            annotations = {
              summary = "High CPU usage";
              description = "CPU usage is above 90% (current value: {{ $value }}%)";
            };
          }
        ];
      }
    ];
    alertmanager = {
      enable = true;
      ntfy = {
        enable = true;
        settings.ntfy.notification.topic = "monitoring";
      };
    };
  };
}
