Lightweight LDAP authentication server

- [Github](https://github.com/lldap/lldap)

## Example

```nix
{config, ...}: {
  nps.stacks.lldap = {
    enable = true;

    baseDn = "DC=example,DC=com";
    jwtSecretFile = config.sops.secrets."lldap/jwtSecret".path;
    keySeedFile = config.sops.secrets."lldap/keySeed".path;
    adminPasswordFile = config.sops.secrets."lldap/adminPassword".path;
    bootstrap = {
      users = {
        guest = {
          email = "guest@example.com";
          password_file = config.sops.secrets."users/guest/password".path;
          displayName = "Guest";
          groups = [
            config.nps.stacks.immich.oidc.userGroup
            config.nps.stacks.streaming.jellyfin.oidc.userGroup
          ];
        };
      };
    };
  };
}
```
