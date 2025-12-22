## Example

```nix
{config, ...}: {
  norish = {
    enable = true;

    masterKeyFile = config.sops.secrets."norish/master_key".path;
    db.passwordFile = config.sops.secrets."norish/db_password".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."norish/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
