Full streaming and automation stack containing:

- Sonarr: TV series PVR (automated episode downloads)
  - [Github](https://github.com/Sonarr/Sonarr)
  - [Website](https://sonarr.tv)
- Radarr: Movie manager/automator
  - [Github](https://github.com/Radarr/Radarr)
  - [Website](https://radarr.video)
- Bazarr: Subtitle downloader for Sonarr/Radarr
  - [Github](https://github.com/morpheus65535/bazarr)
  - [Website](https://www.bazarr.media)
- Seerr: Media request/management UI
  - [Github](https://github.com/seerr-team/seerr)
  - [Website](https://seerr.dev)
- Profilarr: Configuration Management Platform for Radarr/Sonarr
  - [Github](https://github.com/Dictionarry-Hub/profilarr)
  - [Website](https://dictionarry.dev/)
- Maintainerr: Library maintenance tool for Plex, Jellyfin and Emby
  - [Github](https://github.com/maintainerr/maintainerr)
  - [Website](https://maintainerr.info)

By default, the following services are enabled:

- Sonarr
- Radarr
- Bazarr

Additionally, the following services can be enabled (disabled by default):

- Seerr
- Profilarr
- Maintainerr

> [!NOTE]
> The following services are provided by separate stacks:
>
> - [qBittorrent (with Gluetun and qui)](https://tarow.github.io/nix-podman-stacks/docs/stacks/qbittorrent.html) — enabled by default via `nps.stacks.streaming.qbittorrent.enable = true`
> - [Prowlarr](https://tarow.github.io/nix-podman-stacks/docs/stacks/prowlarr.html) — enabled by default via `nps.stacks.streaming.prowlarr.enable = true`
> - [SABnzbd](https://tarow.github.io/nix-podman-stacks/docs/stacks/sabnzbd.html) — disabled by default, enable with `nps.stacks.streaming.sabnzbd.enable = true`

## Examples

### Base

```nix
{
  nps.stacks.streaming = {
    enable = true;
  };
}
```

### Full

```nix
{config, ...}: {
  nps.stacks.streaming = {
    enable = true;

    jellyfin = {
      oidc = {
        enable = true;
        clientSecretFile = config.sops.secrets."jellyfin/authelia/client_secret".path;
      };
    };

    profilarr.enable = true;
    seerr.enable = true;
    maintainerr.enable = true;
  };
}
```

## Notes

By default, Jellyfin writes to `/config/cache/transcodes` for transcoding. This can cause a high amount of write operations on the underlying disk.
To avoid this, you can optionally mount a tmpfs into the container:

```nix
{
  nps.stacks.streaming = {
    containers.jellyfin.extraPodmanArgs = [ "--tmpfs=/config/cache/transcodes:size=4G" ];
  };
}
```

Ram size to be determined on what you have available but 4G seems to be sufficient for most transcodes.
Thanks to [@Zer0PointModule](https://github.com/Zer0PointModule) for the hint.