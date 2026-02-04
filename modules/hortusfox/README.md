Collaborative plant management and tracking system

- [Github](https://github.com/danielbrendel/hortusfox-web)
- [Website](https://www.hortusfox.com/)

## Example

```nix
{config, ...}: {
  nps.stacks.hortusfox = {
    enable = true;
    db = {
      userPasswordFile = config.sops.secrets."hortusfox/db_user_password".path;
      rootPasswordFile = config.sops.secrets."hortusfox/db_root_password".path;
    };

    adminEmail = "admin@example.com";

    # Optional, enable Authelia Forward-Auth middleware and use Proxy-Auth for authentication
    containers.hortusfox.forwardAuth.enable = true;
    extraEnv = {
      PROXY_ENABLE = true;
      PROXY_HEADER_EMAIL = "Remote-Email";
      PROXY_HEADER_USERNAME = "Remote-User";
      PROXY_AUTO_SIGNUP = true;
      PROXY_WHITELIST = config.nps.stacks.traefik.ip4;
      PROXY_HIDE_LOGOUT = true;
    };
  };
}
```
