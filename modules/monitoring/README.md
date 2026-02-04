Full monitoring and alerting stack containing:

- Alloy: Log and metric collector
  - [Github](https://github.com/grafana/alloy)
  - [Website](https://grafana.com/docs/alloy/latest/)
- Loki: Log aggregation
  - [Github](https://github.com/grafana/loki)
  - [Website](https://grafana.com/oss/loki/)
- Grafana: Query and visualize metrics
  - [Github](https://github.com/grafana/grafana)
  - [Website](https://grafana.com/)
- Prometheus: Metric collection
  - [Github](https://github.com/prometheus/prometheus)
  - [Website](https://prometheus.io/)
- AlertManager: Sending alerts
  - [Github](https://github.com/prometheus/alertmanager)
  - [Website](https://prometheus.io/docs/alerting/latest/alertmanager/)
- AlertManager-ntfy: Forward alerts to ntfy
  - [Github](https://github.com/alexbakker/alertmanager-ntfy)

## Examples

### Simple

```nix
{
  nps.stacks.monitoring.enable = true;
}
```

### With Grafana OIDC Login

```nix
{config, ...}: {
  nps.stacks.monitoring = {
    enable = true;

    grafana = {
      oidc = {
        enable = true;
        clientSecretHash = "$pbkdf2-sha512$...";
        clientSecretFile = config.sops.secrets."grafana/authelia/client_secret".path;
      };
    };
  };
}
```

### With Prometheus Rules + Ntfy Alerting

```nix
{config, ...}: {
  nps.stacks.monitoring = {
    monitoring.enable = true;

    prometheus.rules.groups = let
      cpuThresh = 90;
      ramThresh = 85;
    in [
      {
        name = "resource.usage";
        interval = "30s";
        rules = [
          {
            alert = "HighCpuUsage";
            expr = ''100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > ${toString cpuThresh}'';
            for = "20m";
            labels = {
              severity = "warning";
            };
            annotations = {
              summary = "High CPU usage";
              description = "CPU usage is above ${toString cpuThresh}% (current value: {{ $value }}%)";
            };
          }
          {
            alert = "HighMemoryUsage";
            expr = ''(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > ${toString ramThresh}'';
            labels = {
              severity = "warning";
            };
            annotations = {
              summary = "High memory usage";
              description = "Memory usage is above ${toString ramThresh}% (current value: {{ $value }}%)";
            };
          }
        ];
      }
    ];

    alertmanager = {
      enable = true;
      ntfy = {
        enable = true;
        tokenFile = config.sops.secrets."ntfy/monitoring/ntfy_access_token".path;
        settings.ntfy.notification.topic = "monitoring";
      };
    };
  };
}
```
