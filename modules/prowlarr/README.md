Indexer manager / proxy for the \*arr apps

- [Github](https://github.com/Prowlarr/Prowlarr)
- [Website](https://prowlarr.com)

> [!NOTE]
> By default Prowlarr also enables the [Flaresolverr](https://tarow.github.io/nix-podman-stacks/docs/stacks/flaresolverr.html) stack, which it uses to bypass Cloudflare protection on indexers.
> To disable this, set `nps.stacks.prowlarr.useFlaresolverr = false`.

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
