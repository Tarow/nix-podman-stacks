## Example

```nix
{config, ...}: {
  filebrowser-quantum = {
    enable = true;
    mounts = {
      ${config.home.homeDirectory} = {
        path = config.home.homeDirectory;
        name = config.home.username;
      };
      ${config.nps.externalStorageBaseDir} = {
        path = "/hdd";
        name = "hdd";
      };
    };
    oidc = {
      enable = true;
      clientSecretHash = "$pbkdf2-sha512$...";
      clientSecretFile = config.sops.secrets."filebrowser-quantum/authelia/client_secret".path;
    };
    settings.auth.methods.password.enabled = false;
  };
}
```
