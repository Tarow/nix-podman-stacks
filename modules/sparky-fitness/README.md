Fitness Tracking Platform

- [Github](https://github.com/CodeWithCJ/SparkyFitness)
- [Website](https://codewithcj.github.io/SparkyFitness/)

## Example

```nix
{config, ...}: {
  nps.stacks.sparky-fitness = {
    enable = true;

    betterAuthSecretFile = config.sops.secrets."sparkyfitness/better_auth_secret".path;
    apiEncryptionKeyFile = config.sops.secrets."sparkyfitness/api_encryption_key".path;
    db.passwordFile = config.sops.secrets."sparkyfitness/db_password".path;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."sparkyfitness/authelia/client_secret".path;
    };
  };
}
```
