Grocery list and recipe manager

- [Github](https://github.com/TomBursch/kitchenowl)
- [Website](https://kitchenowl.org/)

## Example

```nix
{config, ...}: {
  nps.stacks.kitchenowl = {
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
