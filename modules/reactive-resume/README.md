## Example

```nix
{config, ...}: {
  nps.stacks.reactive-resume = {
    enable = true;
    authSecretFile = config.sops.secrets."reactive_resume/auth_secret".path;
    db.passwordFile = config.sops.secrets."reactive_resume/db_password".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."reactive_resume/authelia/client_secret".path;
    };
  };
}
```
