## Example

```nix
{config, ...}: {
  healthchecks = {
    enable = true;
    secretKeyFile = config.sops.secrets."healthchecks/secret_key".path;
    superUserEmail = "admin@example.com";
    superUserPasswordFile = config.sops.secrets."healthchecks/superuser_password".path;
  };
}
```
