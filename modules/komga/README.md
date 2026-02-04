A media server for comics, mangas, BDs, magazines and eBooks

- [Github](https://github.com/gotson/komga)
- [Website](https://komga.org/)

## Example

```nix
{config, ...}: {
  nps.stacks.komga = {
    enable = true;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."komga/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
