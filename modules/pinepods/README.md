Podcast management system

- [Github](https://github.com/madeofpendletonwool/PinePods)
- [Website](https://www.pinepods.online/)

## Example

```nix
{config, ...}: {
  nps.stacks.pinepods = {
    enable = true;
    db.passwordFile = config.sops.secrets."pinepods/db_password".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."pinepods/authelia/client_secret".path;
    };
  };
}
```
