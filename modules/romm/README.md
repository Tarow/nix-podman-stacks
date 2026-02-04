Retro games ROM manager

- [Github](https://github.com/rommapp/romm)
- [Website](https://romm.app/)

## Example

```nix
{config, ...}: {
  nps.stacks.romm = {
    enable = true;

    authSecretKeyFile = config.sops.secrets."romm/auth_secret_key".path;
    romLibraryPath = "${config.nps.externalStorageBaseDir}/romm/library";

    db = {
      userPasswordFile = config.sops.secrets."romm/db/user_password".path;
      rootPasswordFile = config.sops.secrets."romm/db/root_password".path;
    };

    extraEnv = {
      IGDB_CLIENT_ID.fromFile = config.sops.secrets."romm/igdb_client_id".path;
      IGDB_CLIENT_SECRET.fromFile = config.sops.secrets."romm/igdb_client_secret".path;
    };

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."romm/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
