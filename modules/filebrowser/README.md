## Example

```nix
{config, ...}: {
  filebrowser = {
    enable = true;
    mounts = {
      ${config.home.homeDirectory} = "/home";
      ${config.nps.externalStorageBaseDir} = "/hdd";
    };
  };
}
```
