Goals focused project management system

- [Github](https://github.com/Leantime/leantime)
- [Website](https://leantime.io/)

## Example

```nix
{config, ...}: {
  nps.stacks.leantime = {
    enable = true;
    sessionPasswordFile = config.sops.secrets."leantime/session_password".path;
    db = {
      userPasswordFile = config.sops.secrets."leantime/db_user_password".path;
      rootPasswordFile = config.sops.secrets."leantime/db_root_password".path;
    };
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."leantime/authelia/client_secret".path;
    };
  };
}
```
