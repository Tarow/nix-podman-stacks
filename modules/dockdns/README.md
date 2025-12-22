## Example

```nix
{config, ...}: {
  dockdns = {
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
