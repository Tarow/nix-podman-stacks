Minimalistic document archiving platform.

- [Github](https://github.com/papra-hq/papra)
- [Website](https://papra.app/en/)

## Example

```nix
{config, ...}: {
  nps.stacks.papra = {
    enable = true;
    authSecretFile = config.sops.secrets."papra/auth_secret".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."papra/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
