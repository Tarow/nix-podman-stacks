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

## About

- This service is in maintence mode, it's reccommended to use -quantum version!!!
- A file browser for your server
- [Github](https://github.com/filebrowser/filebrowser)
- [Website](https://filebrowser.org/)