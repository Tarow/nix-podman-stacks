Travel companion and adventure tracker

- [Github](https://github.com/seanmorley15/AdventureLog)
- [Website](https://adventurelog.app/)

## Example

```nix
{config, ...}: {
  nps.stacks.adventurelog = {
    enable = true;
    secretKeyFile = config.sops.secrets."adventurelog/secret_key".path;
    db.passwordFile = config.sops.secrets."adventurelog/db_password".path;
    adminProvisioning = {
      username = "admin";
      email = "admin@example.com";
      passwordFile = config.sops.secrets."adventurelog/admin_password".path;
    };
    oidc = {
      registerClient = true;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
