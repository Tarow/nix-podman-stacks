Self-hosted, multi-user digital library

- [Github](https://github.com/booklore-app/booklore)
- [Website](https://booklore.org/)

## Example

```nix
{config, ...}: {
  nps.stacks.booklore = {
    enable = true;
    oidc.registerClient = true;
    db = {
      userPasswordFile = config.sops.secrets."booklore/db_user_password".path;
      rootPasswordFile = config.sops.secrets."booklore/db_root_password".path;
    };
  };
}
```
