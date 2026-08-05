Network documentation, without the drawing

- [Github](https://github.com/scanopy/scanopy)
- [Website](https://scanopy.net/)

## Example

```nix
{config, ...}: {
  nps.stacks.scanopy = {
    enable = true;
    db.passwordFile = config.sops.secrets."scanopy/postgresPassword".path;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."scanopy/authelia_client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
