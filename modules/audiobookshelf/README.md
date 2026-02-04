Self-hosted audiobook and podcast server

- [Github](https://github.com/advplyr/audiobookshelf)
- [Website](https://www.audiobookshelf.org/)

## Example

```nix
{
  nps.stacks.audiobookshelf = {
    enable = true;
    oidc = {
      registerClient = true;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
