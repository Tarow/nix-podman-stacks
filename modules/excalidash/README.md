Self-hosted Excalidraw workspace with saved drawings, collections, real-time collaboration, and version history.

- [Github](https://github.com/ZimengXiong/ExcaliDash)
- [Website](https://excalidash.xyz)

## Example

```nix
{
  config,
  ...
}: {
  nps.stacks.excalidash = {
    enable = true;
    jwtSecretFile = config.sops.secrets."excalidash/jwt_secret".path;
    csrfSecretFile = config.sops.secrets."excalidash/csrf_secret".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."excalidash/authelia/client_secret".path;
      clientSecretHash = "$pbkdf2-sha512$...";
    };
  };
}
```
