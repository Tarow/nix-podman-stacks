All-in-one solution for WireGuard

- [Github](https://github.com/wg-easy/wg-easy)
- [Website](https://wg-easy.github.io/wg-easy/latest/getting-started/)

> [!NOTE]
> On modern hosts wg-easy hooks might fail because the container uses iptables-legacy while the host uses nftables.
> To configure wg-easy to work with nftables, refer to the [documentation](https://wg-easy.github.io/wg-easy/v15.3/examples/tutorials/podman-nft/) to update your `PostUp` & `PostDown` hooks.

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
