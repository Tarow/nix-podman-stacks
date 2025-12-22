## Example

```nix
{
  memos = {
    enable = true;

    oidc = {
      registerClient = true;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
