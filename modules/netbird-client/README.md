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

Set `mode = "rootless"` to use the rootless image with host networking. This allows
the client to reach services through the host IP and published ports; it does not
join the Traefik network.
