SSH and Telnet client made for the Web

- [Github](https://github.com/nirui/sshwifty)

## Example

```nix
{config, ...}: {
  nps.stacks.sshwifty = {
    enable = true;

    settings = {
      SharedKey = "{{ file.Read `${config.sops.secrets."sshwifty/web_password".path}`}}";
    };
  };
}
```
