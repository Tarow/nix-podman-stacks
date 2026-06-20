Inventory and Organization System

- [Github](https://github.com/sysadminsmedia/homebox)
- [Website](https://homebox.software/)

## Example

```nix
{config, ...}: {
  nps.stacks.homebox = {
    enable = true;
    apiKeyPepperFile = config.sops.secrets."homebox/api_key_pepper".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."homebox/authelia/client_secret".path;
    };
  };
}
```
