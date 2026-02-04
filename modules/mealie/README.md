Recipe management app

- [Github](https://github.com/mealie-recipes/mealie)
- [Website](https://mealie.io/)

## Example

```nix
{config, ...}: {
  nps.stacks.mealie = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretHash = "$pbkdf2-sha512$...";
      clientSecretFile = config.sops.secrets."mealie/authelia/client_secret".path;
    };
  };
}
```
