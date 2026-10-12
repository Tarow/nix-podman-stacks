NetBird Client

- [Github](https://github.com/netbirdio/netbird)
- [Website](https://netbird.io/)
- [Docs](https://docs.netbird.io/get-started/install/docker)

## Example

```nix
{config, ...}: {
  # Management server, only needed when self-hosting it
  nps.stacks.netbird-management = {
    enable = true;
    authSecretFile = config.sops.secrets."netbird/auth_secret".path;
    storeEncryptionKeyFile = config.sops.secrets."netbird/encryption_key".path;
    adminProvisioning = {
      email = "admin@example.com";
      passwordFile = config.sops.secrets."netbird/admin_password".path;
    };
    oidc.clientSecretFile = config.sops.secrets."netbird/authelia/client_secret".path;
  };

  nps.stacks.netbird-client = {
    enable = true;
    # Create the key in the dashboard under "Peers" → "Setup Keys"
    setupKeyFile = config.sops.secrets."netbird/setup_key".path;
  };
}
```

`managementUrl` defaults to the `netbird-management` stack, and falls back to
NetBird Cloud when that stack is not enabled. Set it explicitly to use another
deployment.

## Networking notes

The client uses host networking, so the WireGuard interface is created in the
host network namespace. The container needs the `NET_ADMIN`, `SYS_ADMIN` and
`SYS_RESOURCE` capabilities plus `/dev/net/tun` to create it. Routing sysctls
are only passed to Podman when the client is not using host networking; with
host networking, configure IP forwarding on the host instead. See the
[NetBird docs](https://docs.netbird.io/get-started/install/docker).

Reaching services on the host from the container works through Podman's host
gateway, like it does for the other stacks.

## Routing peer

With `enableRouting` (the default), the container forwards traffic between the
overlay network and the host network, so this peer can act as a routing peer for
other NetBird peers. This only enables forwarding in the container: the routes
themselves still have to be configured in the NetBird management service under
"Networks" → "Routes".

```nix
nps.stacks.netbird-client.enableRouting = false;
```
