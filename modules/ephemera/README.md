## Example

```nix
{config, ...}: {
  ephemera = {
    enable = true;
    downloadDirectory = "${config.nps.storageBaseDir}/booklore/bookdrop";
  };
}
```
