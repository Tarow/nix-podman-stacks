## Example

```nix
{config, ...}: {
  wg-easy = {
    enable = true;

    adminPasswordFile = config.sops.secrets."wg-easy/admin_password".path;
    extraEnv = {
      DISABLE_IPV6 = true;
    };
  };
}
```
