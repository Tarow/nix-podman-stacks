Stop unused services and start them on demand

- [Github](https://github.com/sablierapp/sablier)
- [Website](https://sablierapp.dev/)

> [!NOTE]
> When Sablier is enabled, it will configure Traefik to use the `file` provider instead of the default `docker` provider.
> This is required because Quadlet removes containers when they are stopped, so Traefik can no longer discover them through the docker provider.

## Example

```nix
{
  nps.stacks.sablier = {
    enable = true;
    settings = {
      sessions.default-duration = "10m";
    };
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.sablier\.(?!containers($|\.)).*/" />

## Container Extension

Sablier adds the `sablier` container option to the existing `services.podman.containers.<name>` options.
Enabling it for a container opts it into on-demand scaling and applies the matching Sablier middleware in Traefik.

By default a container gets assigned to a group named after its stack (`config.stack`).
Containers in the same group are started together. You can set a custom `group` to group containers from different stacks.

Example:

```nix
{
  nps.stacks.sablier.enable = true;

  nps.stacks.streaming.containers.jellyfin.sablier = {
    enable = true;
    # Optional: group containers across stacks, defaults to the container's stack name
    # group = "media";
  };
}
```

Additional Sablier settings (e.g. `idleReplicas`) are forwarded as `X-Sablier` labels on the systemd unit.
For details see <https://sablierapp.dev/reference/labels/>

Options for the generated Traefik middleware can be set through the `middleware` option. Since all containers of a
group share one middleware, their settings are merged.

```nix
{
  nps.stacks.streaming.containers.jellyfin.sablier = {
    enable = true;
    middleware = {
      sessionDuration = "45m";
      failOpen = true;
      ignoreUserAgent = ["curl" "(?i)uptimerobot"];
      dynamic.displayName = "Media Server";
    };
  };
}
```

For all available options see <https://plugins.traefik.io/plugins/69104ac3b7d4dd76110a1a09/sablier>

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.sablier(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.sablier\.containers\..*/" />
