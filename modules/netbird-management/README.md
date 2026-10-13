Self-hosted NetBird management server and dashboard

- [Github](https://github.com/netbirdio/netbird)
- [Website](https://netbird.io/)

## Example

```nix
{config, ...}: {
  nps.stacks.netbird-management = {
    enable = true;
    authSecretFile = config.sops.secrets."netbird/auth_secret".path;
    storeEncryptionKeyFile = config.sops.secrets."netbird/encryption_key".path;
    adminProvisioning = {
      email = "admin@example.com";
      passwordFile = config.sops.secrets."netbird/admin_password".path;
    };
    oidc = {
      clientSecretFile = config.sops.secrets."netbird/authelia/client_secret".path;
    };
  };
}
```

See the [NetBird client stack](/stacks/netbird-client) to enroll peers.
