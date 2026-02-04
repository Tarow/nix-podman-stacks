Photo and video management solution

- [Github](https://github.com/immich-app/immich)
- [Website](https://immich.app/)

## Example

```nix
{config, lib, ...}: {
  nps.stacks.immich = {
    enable = true;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."immich/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
    db.passwordFile = config.sops.secrets."immich/db_password".path;

    settings = {
      oauth.autoLaunch = true;
      passwordLogin.enabled = false;
    };
  };
}
```
