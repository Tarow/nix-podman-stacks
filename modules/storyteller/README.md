Self-hosted platform for creating and reading ebooks with
synced narration

- [Gitlab](https://gitlab.com/storyteller-platform/storyteller)
- [Website](https://storyteller-platform.gitlab.io/storyteller/)

## Example

```nix
{
  nps.stacks.storyteller = {
    enable = true;

    secretKeyFile = config.sops.secrets."storyteller/secret_key".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."storyteller/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
