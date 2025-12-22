## Example

```nix
{config, ...}: {
  beszel = {
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
