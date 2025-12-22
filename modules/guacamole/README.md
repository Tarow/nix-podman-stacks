## Example

```nix
{config, ...}: {
  guacamole = {
    enable = true;

    db.passwordFile = config.sops.secrets."guacamole/db_password".path;
    oidc.enable = true;
  };
}
```
