## Example

```nix
{config, ...}: {
  kitchenowl = {
    enable = true;

    jwtSecretFile = config.sops.secrets."kitchenowl/jwt_secret".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."kitchenowl/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
