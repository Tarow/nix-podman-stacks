Collaborative Travel Planner

- [Github](https://github.com/mauriceboe/TREK)

## Example

```nix
{config, ...}: {
  nps.stacks.trek = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretHash = "$pbkdf2-sha512$...";
      clientSecretFile = config.sops.secrets."trek/authelia/client_secret".path;
    };
  };
}
```
