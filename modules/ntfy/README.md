## Examples

### Simple

```nix
{
  ntfy.enable = true;
}
```

### With Authentication

```nix
{config, ...}: {
  ntfy = {
    enable = true;

    settings = {
      enable-login = true;
      auth-default-access = "deny-all";
      auth-users = [
        "admin:{{ file.Read `${config.sops.secrets."users/admin/password_bcrypt".path}` }}:admin"
        "monitoring:{{ file.Read `${config.sops.secrets."users/monitoring/password_bcrypt".path}` }}:user"
      ];
      auth-access = [
        "monitoring:monitoring:rw"
      ];
      auth-tokens = [
        "monitoring:{{ file.Read `${config.sops.secrets."users/monitoring/ntfy_access_token".path}` }}"
      ];
    };
  };
}
```
