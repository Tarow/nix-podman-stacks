GUI to manage your WireGuard peers and interfaces

- [Github](https://github.com/h44z/wg-portal)
- [Website](https://wgportal.org/latest/)

## Example

```nix
{config, ...}: {
  nps.stacks.wg-portal = {
    enable = true;

    port = 51825;
    settings = {
      advanved.use_ip_v6 = false;
      core = {
        admin_user = "admin";
        # Read admin password from env variable 'ADMIN_PASSWORD'
        admin_password = "\${ADMIN_PASSWORD}";
      };
    };
    # Provide the admin password env variable
    extraEnv.ADMIN_PASSWORD.fromFile = config.sops.secrets."wg-portal/admin_password".path;

    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."wg-portal/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
