## Examples

### Simple

```nix
{
  monitoring.enable = true;
}
```

### With Grafana OIDC Login

```nix
{config, ...}: {
  monitoring = {
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
{
  monitoring = {
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
        tokenFile = config.sops.secrets."users/monitoring/ntfy_access_token".path;
        settings.ntfy.notification.topic = "monitoring";
      };
    };
  };
}
```
