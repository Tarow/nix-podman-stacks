## Example

When this module is enabled, the socket proxy will be automatically used by other stacks that support it.
Example include [Homepage](/stacks/homepage), [Traefik](/stacks/traefik) and [Dozzle](/stacks/dozzle)

```nix
{
  docker-socket-proxy.enable = true;
}
```
