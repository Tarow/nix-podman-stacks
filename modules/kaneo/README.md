Open-Source Project Management Platform

- [Github](https://github.com/usekaneo/kaneo)
- [Website](https://kaneo.app/)

## Example

```nix
{config, ...}: {
  nps.stacks.kaneo = {
    enable = true;
    authSecretFile = config.sops.secrets."kaneo/auth_secret".path;
    db.passwordFile = config.sops.secrets."kaneo/db_password".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."kaneo/authelia/client_secret".path;
    };
  };
}
```
