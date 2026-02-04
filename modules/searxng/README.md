## Example

```nix
{config, ...}: {
  nps.stacks.searxng = {
    enable = true;
    secretKeyFile = config.sops.secrets."searxng/secret_key".path;
  };
}
```

## About

- Self-hosted meta-search engine
- [Github](https://github.com/searxng/searxng)
- [Website](https://docs.searxng.org/)