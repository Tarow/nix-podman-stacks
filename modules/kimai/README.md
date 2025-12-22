## Example

```nix
{config, ...}: {
  kimai = {
    enable = true;

    adminEmail = "admin@example.com";
    adminPasswordFile = config.sops.secrets."kimai/admin_password".path;
    db = {
      userPasswordFile = config.sops.secrets."kimai/db_user_password".path;
      rootPasswordFile = config.sops.secrets."kimai/db_root_password".path;
    };
  };
}
```
