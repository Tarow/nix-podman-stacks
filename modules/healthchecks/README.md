## Example

```nix
{config, ...}: {
  nps.stacks.healthchecks = {
    enable = true;
    secretKeyFile = config.sops.secrets."healthchecks/secret_key".path;
    superUserEmail = "admin@example.com";
    superUserPasswordFile = config.sops.secrets."healthchecks/superuser_password".path;
  };
}
```

## About

- Cron job monitoring
- [Github](https://github.com/healthchecks/healthchecks)
- [Website](https://healthchecks.io/)