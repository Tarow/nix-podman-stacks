## Example

```nix
{config, ...}: {
  jotty = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."jotty/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
