Bookmark-everything app

- [Github](https://github.com/karakeep-app/karakeep)
- [Website](https://karakeep.app/)

## Example

```nix
{config, ...}: {
  nps.stacks.karakeep = {
    enable = true;

    oidc = {
      enable = true;
      clientSecretHash = "$pbkdf2-sha512$...";
      clientSecretFile = config.sops.secrets."karakeep/authelia/client_secret".path;
    };
    nextauthSecretFile = config.sops.secrets."karakeep/nextauth_secret".path;
    meiliMasterKeyFile = config.sops.secrets."karakeep/meili_master_key".path;

    containers.karakeep.extraEnv = {
      DISABLE_SIGNUPS = true;
      DISABLE_PASSWORD_AUTH = true;
    };
  };
}
```
