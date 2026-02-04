## Example

```nix
{
  nps.stacks.vaultwarden = {
    enable = true;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."vaultwarden/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```

## About

- Self hosted password manager compatible with bitwarden
- [Github](https://github.com/dani-garcia/vaultwarden)