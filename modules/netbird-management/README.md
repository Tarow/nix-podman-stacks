Open Source Zero Trust Networking

- [Github](https://github.com/netbirdio/netbird)
- [Website](https://netbird.io/)

NetBird's combined server uses embedded Dex as its token issuer. The dashboard
authenticates against that issuer, which brokers login through the mandatory
Authelia OIDC client. Configure an Authelia client secret, an initial owner email
and a password file:

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

Peers are enrolled with the NetBird client stack
([docs page](/stacks/netbird-client)) or by installing the client on the device itself.

## Setup Keys

Register unattended peers with a setup key, created in the dashboard under
"Peers" → "Setup Keys". The key has to reach the client as a file, for example
via [sops-nix](https://github.com/Mic92/sops-nix):

```nix
nps.stacks.netbird-client = {
  enable = true;
  setupKeyFile = config.sops.secrets."netbird/setup_key".path;
};
```
