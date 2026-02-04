App designed to help you organize tasks and chores effectively

- [Github](https://github.com/donetick/donetick)
- [Website](https://donetick.com/)

## Example

```nix
{config, ...}: {
  nps.stacks.donetick = {
    enable = true;

    # Disable user registration, so only OIDC login is possible
    settings.is_user_creation_disabled = true;

    jwtSecretFile = config.sops.secrets."donetick/jwt_secret".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."donetick/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
