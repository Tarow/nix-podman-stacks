Clientless remote desktop gateway

- [Github](https://github.com/apache/guacamole-client)
- [Website](https://freshrss.org/)

## Example

### User-Mapping XML

```nix

{config, ...}: {
  nps.stacks.guacamole = {
    enable = true;

    userMappingXml = ''
      <user-mapping>
        <authorize username="example_user" password="{{ file.Read `${config.sops.secrets."guacamole_password".path}`}}">
          <connection name="Host SSH">
              <protocol>ssh</protocol>
              <param name="hostname">host.containers.internal</param>
              <param name="port">22</param>
              <param name="username">hostuser</param>
              <param name="private-key">{{ file.Read `${config.sops.secrets."guacamole/ssh_private_key".path}` }}</param>
              <param name="command">bash</param>
          </connection>
        </authorize>
      </user-mapping>
    '';
  };
}
```

### OIDC

```nix
{config, ...}: {
  nps.stacks.guacamole = {
    enable = true;

    db.passwordFile = config.sops.secrets."guacamole/db_password".path;
    oidc.enable = true;
  };
}
```
