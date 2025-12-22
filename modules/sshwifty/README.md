## Example

```nix
{config, ...}: {
  sshwifty = {
    enable = true;

    settings = {
      SharedKey = "{{ file.Read `${config.sops.secrets."sshwifty/web_password".path}`}}";
    };
  };
}
```
