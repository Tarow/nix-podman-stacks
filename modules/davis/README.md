## Example

```nix
{
  davis = {
    enable = true;

    adminPasswordFile = config.sops.secrets."davis/admin_password".path;
    db = {
      userPasswordFile = config.sops.secrets."davis/db_user_password".path;
      rootPasswordFile = config.sops.secrets."davis/db_root_password".path;
    };

    # LLDAP-managed users will be able to log in
    enableLdapAuth = true;
  };
}
```
