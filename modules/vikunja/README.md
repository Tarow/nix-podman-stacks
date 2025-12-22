## Example

```nix
{config, ...}: {
  vikunja = {
    enable = true;

    jwtSecretFile = config.sops.secrets."vikunja/jwt_secret".path;

    settings = {
      service.enableregistration = false;
      auth.local.enabled = false;
    };
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."vikunja/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
