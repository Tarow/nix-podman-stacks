## Example

```nix
{
  streaming = {
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
  };
}
```
