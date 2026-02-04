Recipe management and meal planning application

- [Github](https://github.com/TandoorRecipes/recipes)
- [Website](https://tandoor.dev/)

## Example

```nix
{config, ...}: {
  nps.stacks.tandoor = {
    enable = true;

    secretKeyFile = config.sops.secrets."tandoor/secret_key".path;
    db.passwordFile = config.sops.secrets."tandoor/db_password".path;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."tandoor/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };

    containers.tandoor.extraEnv = {
      # https://docs.tandoor.dev/system/configuration/#default-permissions
      SOCIAL_DEFAULT_ACCESS = 1;
      SOCIAL_DEFAULT_GROUP = "user";
    };
  };
}
```
