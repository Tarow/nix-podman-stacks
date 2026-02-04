Notification service

- [Github](https://github.com/binwiederhier/ntfy)
- [Website](https://ntfy.sh/)

## Examples

### Simple

```nix
{
  nps.stacks.ntfy.enable = true;
}
```

### With Authentication

```nix
{config, ...}: {
  nps.stacks.ntfy = {
    enable = true;

    settings = {
      enable-login = true;
      auth-default-access = "deny-all";
      auth-users = [
        "admin:{{ file.Read `${config.sops.secrets."ntfy/admin/password_bcrypt".path}` }}:admin"
        "monitoring:{{ file.Read `${config.sops.secrets."ntfy/monitoring/password_bcrypt".path}` }}:user"
      ];
      auth-access = [
        "monitoring:monitoring:rw"
      ];
      auth-tokens = [
        "monitoring:{{ file.Read `${config.sops.secrets."ntfy/monitoring/ntfy_access_token".path}` }}"
      ];
    };
  };
}
```
