Bambu Lab printer management, print archiving, and queueing.

- [Github](https://github.com/maziggy/bambuddy)
- [Website](https://bambuddy.cool/)
- [Documentation](https://wiki.bambuddy.cool/)

## Example

```nix
{config, ...}: {
  nps.stacks.bambuddy = {
    enable = true;
    orcaSlicer.enable = true;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."bambuddy/authelia/client_secret".path;
    };
  };
}
```
