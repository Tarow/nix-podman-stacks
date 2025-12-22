## Example

```nix
{config, lib, ...}: {
  immich = {
    enable = true;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."immich/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
    dbPasswordFile = config.sops.secrets."immich/db_password".path;

    settings = {
      oauth.autoLaunch = lib.mkForce true;
      passwordLogin.enabled = lib.mkForce false;
    };
  };
}
```
