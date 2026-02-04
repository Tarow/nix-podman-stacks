Stremio meta addon

- [Github](https://github.com/Viren070/aiostreams)
- [Website](https://aiostreams.elfhosted.com/stremio/configure)

## Example

```nix
{config, ...}:{
  nps.stacks.aiostreams = {
    enable = true;
    secretKeyFile = config.sops.secrets."aiostreams/secret_key".path;
    extraEnv = {
      TMDB_ACCESS_TOKEN.fromFile = config.sops.secrets."aiostreams/tmdb_access_token".path;
    };
  };
}
```
