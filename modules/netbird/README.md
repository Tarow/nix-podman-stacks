Open Source Zero Trust Networking

- [Github](https://github.com/netbirdio/netbird)
- [Website](https://netbird.io/)

## Example

```nix
{config, ...}: {
  nps.stacks.netbird = {
    enable = true;
    authSecretFile = config.sops.secrets."netbird/auth_secret".path;
    storeEncryptionKeyFile = config.sops.secrets."netbird/encryption_key".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."netbird/authelia/client_secret".path;
    };
  };
}
```
