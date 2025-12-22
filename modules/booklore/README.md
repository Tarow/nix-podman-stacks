## Example

```nix
{config, ...}: {
  booklore = {
    enable = true;
    oidc.registerClient = true;
    db = {
      userPasswordFile = config.sops.secrets."booklore/db_user_password".path;
      rootPasswordFile = config.sops.secrets."booklore/db_root_password".path;
    };
  };
}
```
