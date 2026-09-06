qBittorrent stack with optional VPN routing through Gluetun:

- Gluetun: VPN client for containers
  - [Github](https://github.com/qdm12/gluetun)
  - [Website](https://github.com/qdm12/gluetun-wiki)
- qBittorrent: BitTorrent client
  - [Github](https://github.com/qbittorrent/qBittorrent)
  - [Website](https://www.qbittorrent.org)
- qui: Alternative qBittorrent interface
  - [Github](https://github.com/autobrr/qui)
  - [Website](https://getqui.com)

By default, qBittorrent routes all traffic through Gluetun. To run qBittorrent without a VPN, set `gluetun.enable = false`.

## Examples

### Base

```nix
{config, ...}: {
  nps.stacks.qbittorrent = {
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
  nps.stacks.qbittorrent = {
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

    extraEnv = {
      TORRENTING_PORT.fromFile = config.sops.secrets."qbittorrent/torrenting_port".path;
    };

    qui = {
      enable = true;
      oidc = {
        enable = true;
        clientSecretFile = config.sops.secrets."qui/authelia/client_secret".path;
      };
    };
  };
}
```

## Notes

Other stacks can route their containers through the Gluetun VPN by setting `network = ["container:gluetun"]` and `dependsOnContainer = ["gluetun"]` on the container.
To instead expose qBittorrent/Gluetun on another stack's network, set `nps.containers.gluetun.network = ["<stack>"]` (or `nps.containers.qbittorrent.network` when Gluetun is disabled).