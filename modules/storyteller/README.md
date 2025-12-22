## Example

```nix
{
  storyteller = {
    enable = true;

    secretKeyFile = config.sops.secrets."storyteller/secret_key".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."storyteller/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
