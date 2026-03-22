Self-hosted, multi-user digital library

- [Github](https://github.com/grimmory-tools/grimmory)
- [Website](https://grimmory.org/)

## Example

```nix
{config, ...}: {
  nps.stacks.grimmory = {
    enable = true;
    oidc.registerClient = true;
    db = {
      userPasswordFile = config.sops.secrets."grimmory/db_user_password".path;
      rootPasswordFile = config.sops.secrets."grimmory/db_root_password".path;
    };
  };
}
```
