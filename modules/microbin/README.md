Text and file sharing pastebin

- [Github](https://github.com/szabodanika/microbin)
- [Website](https://microbin.eu/)

## Example

```nix
{config, ...}: {
  nps.stacks.microbin = {
    enable = true;

    extraEnv = {
      MICROBIN_ADMIN_USERNAME = "admin";
      MICROBIN_ADMIN_PASSWORD.fromFile = config.sops.secrets."microbin/admin_password".path;
    };
  };
}
```
