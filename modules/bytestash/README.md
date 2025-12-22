## Example

```nix
{
  bytestash = {
    enable = true;
    jwtSecretFile = config.sops.secrets."bytestash/jwt_secret".path;
  };
}
```
