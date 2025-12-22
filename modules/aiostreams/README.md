## Example

```nix
{config, ...}:{
  aiostreams = {
    enable = true;
    secretKeyFile = config.sops.secrets."aiostreams/secret_key".path;
    extraEnv = {
      TMDB_ACCESS_TOKEN.fromFile = config.sops.secrets."aiostreams/tmdb_access_token".path;
    };
  };
}
```
