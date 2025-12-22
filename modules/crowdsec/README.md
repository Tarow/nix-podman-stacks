## Example

```nix
{
  crowdsec = {
    enable = true;
    enableGrafanaDashboard = true;
    enablePrometheusExport = true;

    # Optional, to enroll the security engine to the console
    extraEnv = {
      ENROLL_INSTANCE_NAME = "homeserver";
      ENROLL_KEY.fromFile = config.sops.secrets."crowdsec/enroll_key".path;
    };
  };
}
```
