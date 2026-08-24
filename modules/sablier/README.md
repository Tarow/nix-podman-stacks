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
