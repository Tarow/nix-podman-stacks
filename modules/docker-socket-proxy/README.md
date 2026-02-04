Security-enhanced proxy for the Docker (works with podman too) Socket

- [Github](https://github.com/Tecnativa/docker-socket-proxy)

## Example

When this module is enabled, the socket proxy will be automatically used by other stacks that support it.
Example include [Homepage](/stacks/homepage), [Traefik](/stacks/traefik) and [Dozzle](/stacks/dozzle)

```nix
{
  nps.stacks.docker-socket-proxy.enable = true;
}
```
