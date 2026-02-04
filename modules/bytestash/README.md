Web application designed to store, organise, and manage your code snippets efficiently

- [Github](https://github.com/jordan-dalby/ByteStash)

## Example

```nix
{
  nps.stacks.bytestash = {
    enable = true;
    jwtSecretFile = config.sops.secrets."bytestash/jwt_secret".path;
  };
}
```
