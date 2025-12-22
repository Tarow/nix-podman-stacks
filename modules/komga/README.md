## Example

```nix
{config, ...}: {
  komga = {
    enable = true;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."komga/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
