Personal subscription tracker

- [Github](https://github.com/ellite/Wallos)
- [Website](https://wallosapp.com/)

## Example

```nix
{config, ...}: {
  nps.stacks.wallos = {
    enable = true;
    oidc = {
      registerClient = true;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
