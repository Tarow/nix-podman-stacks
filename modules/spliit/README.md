Self-hosted expense sharing

- [Github](https://github.com/spliit-app/spliit)
- [Website](https://spliit.app/)

## Example

```nix
{config, ...}: {
  nps.stacks.spliit = {
    enable = true;

    db.passwordFile = config.sops.secrets."spliit/db_password".path;

    extraEnv = {
      DEFAULT_CURRENCY_CODE = "EUR";
    };
  };
}
```
