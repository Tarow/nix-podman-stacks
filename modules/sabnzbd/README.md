Usenet client

- [Github](https://github.com/sabnzbd/sabnzbd)
- [Website](https://sabnzbd.org/)

## Example

```nix
{
  nps.stacks.sabnzbd = {
    enable = true;

    configIni = ''
      [misc]
      host_whitelist_entry = sabnzbd.example.com
    '';
  };
}
```