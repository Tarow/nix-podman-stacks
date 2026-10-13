NetBird client for connecting this host to a management server

- [Github](https://github.com/netbirdio/netbird)
- [Website](https://netbird.io/)
- [Docs](https://docs.netbird.io/get-started/install/docker)

## Example

```nix
{config, ...}: {
  nps.stacks.netbird-client = {
    enable = true;
    setupKeyFile = config.sops.secrets."netbird/setup_key".path;
  };
}
```

`managementUrl` defaults to the enabled `netbird-management` stack or NetBird Cloud.

Set `enableRouting = false` to disable forwarding for this peer (enabled by default).

```nix
nps.stacks.netbird-client.enableRouting = false;
```
