Unified web interface for searching and aggregating books and audiobook downloads

- [Github](https://github.com/calibrain/shelfmark)

## Example

```nix
{config, ...}: {
  nps.stacks.shelfmark = {
    enable = true;
    downloadDirectory = "${config.nps.storageBaseDir}/grimmory/bookdrop";
    useProwlarr = true;
    useQbittorrent = true;

    extraEnv = {
      PROWLARR_API_KEY.fromFile = config.sops.secrets."prowlarr/api_key".path;
      QBITTORRENT_USERNAME = "admin";
      QBITTORRENT_PASSWORD.fromFile = config.sops.secrets."qbittorrent/password".path;
    };
  };
}
```

For a full list of environment variables, see the [Shelfmark documentation](https://github.com/calibrain/shelfmark/blob/main/docs/environment-variables.md).