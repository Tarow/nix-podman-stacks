## Example

```nix
{config, ...}: {
  authelia = {
    enable = true;
    jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
    sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
    storageEncryptionKeyFile = config.sops.secrets."authelia/encryption_key".path;
    oidc = {
      enable = true;
      hmacSecretFile = config.sops.secrets."authelia/oidc_hmac_secret".path;
      jwksRsaKeyFile = config.sops.secrets."authelia/oidc_rsa_pk".path;
    };
    sessionProvider = "redis";
  };
}
```
