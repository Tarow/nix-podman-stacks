Dynamic DNS updater

- [Github](https://github.com/qdm12/ddns-updater)

## Example

```nix
{config, ...}: {
  nps.stacks.ddns-updater = {
    enable = true;
    settings = [
      {
        provider = "duckdns";
        domain = "example.duckdns.org";
        token = "{{ file.Read `${config.sops.secrets."DUCKDNS_TOKEN".path}`}}";
        ip_version = "ipv4";
      }
    ];
  };
}
```
