Full streaming and automation stack containing:

- Gluetun: VPN client for containers
  - [Github](https://github.com/qdm12/gluetun)
  - [Website](https://github.com/qdm12/gluetun-wiki)
- qBittorrent: BitTorrent client
  - [Github](https://github.com/qbittorrent/qBittorrent)
  - [Website](https://www.qbittorrent.org)
- Sonarr: TV series PVR (automated episode downloads)
  - [Github](https://github.com/Sonarr/Sonarr)
  - [Website](https://sonarr.tv)
- Radarr: Movie manager/automator
  - [Github](https://github.com/Radarr/Radarr)
  - [Website](https://radarr.video)
- Bazarr: Subtitle downloader for Sonarr/Radarr
  - [Github](https://github.com/morpheus65535/bazarr)
  - [Website](https://www.bazarr.media)
- Prowlarr: Indexer manager / proxy for the \*arr apps
  - [Github](https://github.com/Prowlarr/Prowlarr)
  - [Website](https://prowlarr.com)
- Seerr: Media request/management UI
  - [Github](https://github.com/seerr-team/seerr)
  - [Website](https://seerr.dev)
- qui: Alternative qBittorrent interfacew
  - [Github](https://github.com/autobrr/qui)
  - [Website](https://getqui.com)
- Profilarr: Configuration Management Platform for Radarr/Sonarr
  - [Github](https://github.com/Dictionarry-Hub/profilarr)
  - [Website](https://dictionarry.dev/)

By default, the following services are enabled:

- Gluetun
- qBittorrent
- Sonarr
- Radarr
- Bazarr
- Prowlarr

Additionally, the following services can be enabled (disabled by default):

- Seerr
- qui
- Profilarr

## Examples

### Base

```nix
{config, ...}: {
  nps.stacks.streaming = {
    enable = true;

    gluetun = {
      vpnProvider = "airvpn";
      wireguardPrivateKeyFile = config.sops.secrets."gluetun/wg_pk".path;
      wireguardPresharedKeyFile = config.sops.secrets."gluetun/wg_psk".path;
      wireguardAddressesFile = config.sops.secrets."gluetun/wg_address".path;
    };
  };
}
```

### Full

```nix
{config, ...}: {
  nps.stacks.streaming = {
    enable = true;

    gluetun = {
      vpnProvider = "airvpn";
      wireguardPrivateKeyFile = config.sops.secrets."gluetun/wg_pk".path;
      wireguardPresharedKeyFile = config.sops.secrets."gluetun/wg_psk".path;
      wireguardAddressesFile = config.sops.secrets."gluetun/wg_address".path;

      extraEnv = {
        FIREWALL_VPN_INPUT_PORTS.fromFile = config.sops.secrets."qbittorrent/torrenting_port".path;
      };
    };

    qbittorrent.extraEnv = {
      TORRENTING_PORT.fromFile = config.sops.secrets."qbittorrent/torrenting_port".path;
    };

    jellyfin = {
      oidc = {
        enable = true;
        clientSecretFile = config.sops.secrets."jellyfin/authelia/client_secret".path;
      };
    };

    qui = {
      enable = true;
      oidc = {
        enable = true;
        clientSecretFile = config.sops.secrets."qui/authelia/client_secret".path;
      };
    };

    profilarr.enable = true;
    seerr.enable = true;
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
