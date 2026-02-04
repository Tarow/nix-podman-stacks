A file browser for your server

- [Github](https://github.com/filebrowser/filebrowser)
- [Website](https://filebrowser.org/)

> [!WARNING]
> This service is in maintence mode, it's recommended to use -quantum version

## Example

```nix
{config, ...}: {
  nps.stacks.filebrowser = {
    enable = true;
    mounts = {
      ${config.home.homeDirectory} = "/home";
      ${config.nps.externalStorageBaseDir} = "/hdd";
    };
  };
}
```
