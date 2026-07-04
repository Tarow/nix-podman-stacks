Self-Hostable Location History Tracker

- [Github](https://github.com/Freika/dawarich)
- [Website](https://dawarich.app)

## Example

```nix
{config, ...}: {
  nps.stacks.dawarich = {
    enable = true;
    secretKeyFile = config.sops.secrets."dawarich/secret_key".path;
    db.passwordFile = config.sops.secrets."dawarich/db_password".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."dawarich/authelia/client_secret".path;
    };
  };
}
```
