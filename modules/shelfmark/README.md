Unified web interface for searching and aggregating books and audiobook downloads

- [Github](https://github.com/calibrain/shelfmark)

## Example

```nix
{config, ...}: {
  nps.stacks.shelfmark = {
    enable = true;
    downloadDirectory = "${config.nps.storageBaseDir}/booklore/bookdrop";
  };
}
```
