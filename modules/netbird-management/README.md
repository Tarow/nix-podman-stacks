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
      enable = true;
      clientSecretFile = config.sops.secrets."netbird/authelia/client_secret".path;
    };
  };
}
```

`adminProvisioning` creates the initial owner only while NetBird setup is incomplete. `oidc.enable`
configures the Authelia client in Nix and registers the provider during initial setup. The
[setup API](https://docs.netbird.io/selfhosted/automated-setup) is only available before setup
completes, so enabling OIDC later will not register the provider. Manage later provider changes in
the NetBird web UI. Keep OIDC enabled in Nix to retain its Authelia client configuration.

See the [NetBird client stack](/stacks/netbird-client) to enroll peers.
