App for checklists and notes

- [Github](https://github.com/fccview/jotty)
- [Website](https://jotty.page/)

## Example

```nix
{config, ...}: {
  nps.stacks.jotty = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."jotty/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
