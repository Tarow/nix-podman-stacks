Self-hosted time tracking

- [Github](https://github.com/DRYTRIX/TimeTracker)
- [Website](https://timetracker.drytrix.com/)

## Example

```nix
{config, ...}: {
  nps.stacks.timetracker = {
    enable = true;

    secretKeyFile = config.sops.secrets."timetracker/secret_key".path;
    db.passwordFile = config.sops.secrets."timetracker/db_password".path;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."timetracker/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
