All-in-one solution for WireGuard

- [Github](https://github.com/wg-easy/wg-easy)
- [Website](https://wg-easy.github.io/wg-easy/latest/getting-started/)

## Example

```nix
{config, ...}: {
  nps.stacks.wg-easy = {
    enable = true;

    adminPasswordFile = config.sops.secrets."wg-easy/admin_password".path;
    extraEnv = {
      DISABLE_IPV6 = true;
    };
  };
}
```
