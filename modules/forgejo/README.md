Self-hosted Git server

- [Codeberg](https://codeberg.org/forgejo/forgejo)
- [Website](https://forgejo.org/)

## Examples

### Simple

```nix
{config, ...}: {
  nps.stacks.forgejo = {
    enable = true;

    lfsJwtSecretFile = config.sops.secrets."forgejo/lfs_jwt_secret".path;
    secretKeyFile = config.sops.secrets."forgejo/secret_key".path;
    internalTokenFile = config.sops.secrets."forgejo/internal_token".path;
    jwtSecretFile = config.sops.secrets."forgejo/jwt_secret".path;
  };
}
```

### With Automatic Admin Provisioning

```nix
{config, ...}: {
  nps.stacks.forgejo = {
    enable = true;

    lfsJwtSecretFile = config.sops.secrets."forgejo/lfs_jwt_secret".path;
    secretKeyFile = config.sops.secrets."forgejo/secret_key".path;
    internalTokenFile = config.sops.secrets."forgejo/internal_token".path;
    jwtSecretFile = config.sops.secrets."forgejo/jwt_secret".path;

    adminProvisioning = {
      username = "forgejo";
      email = "admin@example.com";
      passwordFile = config.sops.secrets."forgejo/admin_password".path;
    };
  };
}
```

### With OIDC Login

```nix
{config, ...}: {
  nps.stacks.forgejo = {
    enable = true;

    lfsJwtSecretFile = config.sops.secrets."forgejo/lfs_jwt_secret".path;
    secretKeyFile = config.sops.secrets."forgejo/secret_key".path;
    internalTokenFile = config.sops.secrets."forgejo/internal_token".path;
    jwtSecretFile = config.sops.secrets."forgejo/jwt_secret".path;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."forgejo/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```

### With Postgres

```nix
{config, ...}: {
  nps.stacks.forgejo = {
    enable = true;

    lfsJwtSecretFile = config.sops.secrets."forgejo/lfs_jwt_secret".path;
    secretKeyFile = config.sops.secrets."forgejo/secret_key".path;
    internalTokenFile = config.sops.secrets."forgejo/internal_token".path;
    jwtSecretFile = config.sops.secrets."forgejo/jwt_secret".path;

    db = {
      type = "postgres";
      passwordFile = config.sops.secrets."forgejo/db_password".path;
    };
  };
}
```
