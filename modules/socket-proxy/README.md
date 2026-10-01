Security-enhanced proxy for the Docker/Podman Socket

- [Github](https://github.com/wollomatic/socket-proxy)
- [Allowlist library](https://github.com/wollomatic/socket-proxy/wiki/Allowlist-Library)
- [Docker API regex pattern index](https://github.com/wollomatic/socket-proxy/wiki/Docker-API-regex-pattern-index)

## Example

```nix
{config, ...}: {
  nps.stacks.socket-proxy.enable = true;
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.socket-proxy\.(?!containers($|\.)).*/" />

## Container Extension

The socket-proxy adds the `socketProxyPermissions` option to the existing
`services.podman.containers.<name>` options. Values are regex patterns per HTTP method, either from
`sections` or custom. Setting it extends the module defaults, use `lib.mkForce` to replace them.

If a container has `socketProxyPermissions` configured, the container will automatically join the `socket-proxyy` network.

```nix
{config, lib, ...}: {
  nps.stacks.mystack.containers.mycontainer.socketProxyPermissions = {
    GET = [
      config.nps.stacks.socket-proxy.sections.containers
      "some custom regexp"
    ];
  };
}
```

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.socketProxyPermissions(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.socket-proxy\.containers\..*/" />
