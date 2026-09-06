Indexer manager / proxy for the \*arr apps

- [Github](https://github.com/Prowlarr/Prowlarr)
- [Website](https://prowlarr.com)

## Example

```nix
{config, ...}: {
  nps.stacks.prowlarr = {
    enable = true;
    db = {
      type = "postgres";
      passwordFile = config.sops.secrets."prowlarr/db_password".path;
    };
  };
}
```
