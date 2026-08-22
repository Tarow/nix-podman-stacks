Stop unused services and start them on demand

- [Github](https://github.com/sablierapp/sablier)
- [Website](https://sablierapp.dev/)

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
