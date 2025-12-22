## Example

```nix
{config, ...}: {
  microbin = {
    enable = true;

    extraEnv = {
      MICROBIN_ADMIN_USERNAME = "admin";
      MICROBIN_ADMIN_PASSWORD.fromFile = config.sops.secrets."microbin/admin_password".path;
    };
  };
}
```
