DNS proxy and ad-blocker for the local network

- [Github](https://github.com/0xERR0R/blocky)
- [Website](https://0xerr0r.github.io/blocky/latest/)

## Example

```nix
{
  nps.stacks.blocky = {
    enable = true;
    enableGrafanaDashboard = true;
    enablePrometheusExport = true;
  };
}
```
