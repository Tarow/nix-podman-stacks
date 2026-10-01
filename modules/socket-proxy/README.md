Security-enhanced proxy for the Docker (works with Podman too) Socket

- [Github](https://github.com/wollomatic/socket-proxy)
- [Allowlist library](https://github.com/wollomatic/socket-proxy/wiki/Allowlist-Library)
- [Docker API regex pattern index](https://github.com/wollomatic/socket-proxy/wiki/Docker-API-regex-pattern-index)

## Example

When this module is enabled, the socket proxy will be automatically used by other stacks that support it.
Examples include [Homepage](/stacks/homepage), [Traefik](/stacks/traefik) and [Dozzle](/stacks/dozzle)

```nix
{
  nps.stacks.socket-proxy.enable = true;
}
```

## Access Control

Access is granted per container, not per endpoint pattern:

1. A container is allowed to talk to the proxy when it carries `socket-proxy.allow.*` labels and
   shares a network with the proxy. Its requests are then matched against those labels only.
2. Every other client is denied. The client allowlist (`SP_ALLOWFROM`) is left at its default
   `127.0.0.1/32` and the proxy has no endpoint allowlist of its own, so neither the host nor any
   unlabelled container can use it.

> [!NOTE]
> Leave `SP_ALLOWFROM` unset. Adding consumer containers would only let them connect, they would
> still have no allowlist to match against, because the labels of a container take precedence.

## Permissions

`nps.stacks.socket-proxy.sections` holds a regex per API section, built from the
[regex pattern index](https://github.com/wollomatic/socket-proxy/wiki/Docker-API-regex-pattern-index):
an optional API version prefix, the API section, and the optional object id, endpoint and query
string. A stack names the sections it needs per HTTP method and passes them to
`mkSocketProxyOptionModule`, which turns them into `socket-proxy.allow.*` container labels:

```nix
{
  lib,
  config,
  ...
}: {
  imports = [
    (import ../socket-proxy/mkSocketProxyOptionModule.nix {
      stack = name;
      permissions = {
        GET = [
          config.nps.stacks.socket-proxy.sections.containers
          config.nps.stacks.socket-proxy.sections.info
          config.nps.stacks.socket-proxy.sections.events
        ];
      };
    })
  ];
}
```

A permission value is always a list of patterns, so a custom regex can be added next to the
sections:

```nix
permissions = {
  GET = [sections.containers "some custom regexp"];
  POST = [sections.containers];
};
```

| Stack         | `GET` sections                              |
| ------------- | ------------------------------------------- |
| traefik       | `containers`, `info`, `events`              |
| crowdsec      | `containers`, `info`, `events`              |
| homepage      | `containers`, `info`, `events`              |
| dozzle        | `containers`, `images`, `info`, `events`    |
| beszel        | `containers`, `info`                        |
| dockdns       | `containers`, `events`                      |
| monitoring    | `containers`, `networks` (alloy)            |
| glance        | `containers`                                |
| dynacat       | `containers`                                |
| pangolin-newt | `containers`                                |

`/version` and `/_ping` are added to every consumer automatically by `mkSocketProxyOptionModule`:
Docker clients need them for API version negotiation, and a per-container allowlist replaces the
default allowlist of the proxy, so they cannot be granted globally.

Setting `socketProxyPermissions` on a container extends this list, it does not replace it. Use
`lib.mkForce` to replace it outright.

> [!IMPORTANT]
> Use POSIX character classes such as `[[:digit:]]` instead of `\d` and `[[:graph:]]` instead of
> `\S`. Backslashes are mangled when passed through systemd, which silently empties the allowlist.

## Container Extension

The socket-proxy adds the `socketProxyPermissions` option to the existing `services.podman.containers.<name>` options.
Stacks that talk to the Docker API set it to the endpoints they need, which are turned into `socket-proxy.allow.*` container labels.
The first pattern per method uses the plain `socket-proxy.allow.<method>` label, additional patterns are numbered with a dot (`socket-proxy.allow.get.1`, `socket-proxy.allow.get.2`, ...).

Any container can request additional endpoints this way, without declaring a stack:

```nix
{config, lib, ...}: {
  nps.stacks.mystack.containers.mycontainer.socketProxyPermissions = {
    GET = [config.nps.stacks.socket-proxy.sections.containers];
  };
}
```

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.socketProxyPermissions(\..*)?/" />

## Socket Availability

The proxy verifies the Podman socket on startup and exits if it is unavailable. A watchdog
re-checks it regularly and stops the proxy if the socket disappears, letting systemd restart it.

A container healthcheck is deliberately not configured: the proxy's health endpoint only listens on
`127.0.0.1` inside the container, which Podman's healthcheck execution cannot reach under rootless
Podman, so the healthcheck would always fail and cause a restart loop.
