Lightweight server monitoring platform

- [Github](https://github.com/henrygd/beszel)
- [Website](https://beszel.dev/)

## Example

```nix
{config, ...}: {
  nps.stacks.beszel = {
    enable = true;
    ed25519PrivateKeyFile = config.sops.secrets."beszel/ssh_key".path;
    ed25519PublicKeyFile = config.sops.secrets."beszel/ssh_pub_key".path;
    oidc = {
      registerClient = true;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
