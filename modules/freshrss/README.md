## Example

```nix
{config, ...}: {
  freshrss = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretHash = "$pbkdf2-sha512$...";
      clientSecretFile = config.sops.secrets."freshrss/authelia/client_secret".path;
      cryptoKeyFile = config.sops.secrets."freshrss/authelia/crypto_key".path;
    };
  };
}
```
