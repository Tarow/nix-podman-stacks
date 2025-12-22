## Example

```nix
{config, ...}: {
  mealie = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretHash = "$pbkdf2-sha512$...";
      clientSecretFile = config.sops.secrets."mealie/authelia/client_secret".path;
    };
  };
}
```
