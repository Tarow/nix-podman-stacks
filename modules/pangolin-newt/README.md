## Example

```nix
{config, ...}: {
  pangolin-newt = {
    enable = true;

    enableGrafanaDashboard = true;
    enablePrometheusExport = true;
    extraEnv = {
      PANGOLIN_ENDPOINT.fromFile = config.sops.secrets."pangolin/endpoint".path;
      NEWT_ID.fromFile = config.sops.secrets."pangolin/newt_id".path;
      NEWT_SECRET.fromFile = config.sops.secrets."pangolin/newt_secret".path;
      NEWT_ADMIN_ADDR = ":2112";
      LOG_LEVEL = "INFO";
    };
  };
}
```
