A self-hosted library and reading platform

- [Github](https://github.com/bookorbit/bookorbit)
- [Website](https://bookorbit.app/)

## Example

```nix
{config, ...}: {
  nps.stacks.bookorbit = {
    enable = true;
    libraryPath = "/mnt/hdd/media/books";
    jwtSecretFile = config.sops.secrets."bookorbit/jwt_secret".path;
    podcastEncryptionKeyFile = config.sops.secrets."bookorbit/podcast_encryption_key".path;
    setupBootstrapTokenFile = config.sops.secrets."bookorbit/setup_bootstrap_token".path;
    db.passwordFile = config.sops.secrets."bookorbit/db_password".path;
    oidc = {
      registerClient = true;
      clientSecretHash = "$pbkdf2-sha512$...";
      userGroup = "bookorbit_user";
      adminGroup = "bookorbit_admin";
    };
    tts.enable = true;
  };
}
```
