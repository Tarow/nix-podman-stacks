Dynamic DNS client specifically designed to work with Cloudflare

- [Github](https://github.com/Tarow/dockdns)

## Example

```nix
{config, ...}: {
  nps.stacks.dockdns = {
    enable = true;

    # Cloudflare API-Token for domain "example.com"
    extraEnv.EXAMPLE_COM_API_TOKEN.fromFile = config.sops.secrets."dockdns/cf_api_token".path;
    settings.domains = [
      {
        # Setup Dyn-DNS for one endpoint
        name = "vpn.example.com";
      }
    ];
  };
}
```
