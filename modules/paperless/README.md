Document management system

- [Github](https://github.com/paperless-ngx/paperless-ngx)
- [Website](https://docs.paperless-ngx.com/)

## Example

```nix
{config, ...}: {
  nps.stacks.paperless = {
    enable = true;

    adminProvisioning = {
      username = "admin";
      passwordFile = config.sops.secrets."paperless/admin_password".path;
      email = "admin@example.com";
    };
    secretKeyFile = config.sops.secrets."paperless/secret_key".path;
    db.passwordFile = config.sops.secrets."paperless/db_password".path;
    extraEnv = {
      PAPERLESS_OCR_LANGUAGES = "eng deu";
      PAPERLESS_OCR_LANGUAGE = "eng+deu";
    };

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."paperless/authelia_client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
