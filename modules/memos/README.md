Note-taking service

- [Github](https://github.com/usememos/memos)
- [Website](https://usememos.com/)

## Example

```nix
{
  nps.stacks.memos = {
    enable = true;

    oidc = {
      registerClient = true;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
