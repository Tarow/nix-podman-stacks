{
  dummyHash,
  dummySecretFile,
  ...
}: {
  imports = [
    ../authelia/vm-test.nix
    ../docker-socket-proxy/vm-test.nix
  ];
  nps.stacks.monitoring = {
    enable = true;
    alloy.useSocketProxy = true;
    grafana.oidc = {
      enable = true;
      clientSecretFile = dummySecretFile;
      clientSecretHash = dummyHash;
    };
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
