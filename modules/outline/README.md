Knowledge base

- [Github](https://github.com/outline/outline)
- [Website](https://www.getoutline.com/)

## Example

```nix
{config, ...}: {
  nps.stacks.outline = {
    enable = true;

    secretKeyFile = config.sops.secrets."outline/secret_key".path;
    utilsSecretFile = config.sops.secrets."outline/utils_secret".path;
    db.passwordFile = config.sops.secrets."outline/db_password".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."outline/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
