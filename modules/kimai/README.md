Time tracking application

- [Github](https://github.com/kimai/kimai)
- [Website](https://www.kimai.org/)

## Example

```nix
{config, ...}: {
  nps.stacks.kimai = {
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
