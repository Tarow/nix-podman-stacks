{
  config,
  lib,
  ...
}: {
  tarow.podman = {
    hostIP4Address = "192.168.178.2";
    hostUid = 1000;
    storageBaseDir = "${config.home.homeDirectory}/stacks";
    externalStorageBaseDir = "/mnt/hdd";

    stacks = {
      adguard.enable = true;
      aiostreams = {
        enable = true;
        envFile = config.sops.secrets."aiostreams/env".path;
      };
      audiobookshelf.enable = true;
      blocky.enable = false;
      calibre.enable = true;
      changedetection.enable = true;
      crowdsec = {
        enable = true;
        envFile = config.sops.secrets."crowdsec/env".path;
      };
      dozzle.enable = true;
      filebrowser.enable = true;
      healthchecks = {
        enable = true;
        envFile = config.sops.secrets."healthchecks/env".path;
      };
      homepage.enable = true;
      immich = {
        enable = true;
        envFile = config.sops.secrets."immich/env".path;
        db.envFile = config.sops.secrets."immich/db_env".path;
      };
      monitoring.enable = true;
      paperless = {
        enable = true;
        envFile = config.sops.secrets."paperless/env".path;
        db.envFile = config.sops.secrets."paperless/db_env".path;
        ftp.envFile = config.sops.secrets."paperless/ftp_env".path;
      };
      stirling-pdf.enable = true;
      streaming = {
        enable = true;
        gluetun = {
          vpnProvider = "airvpn";
          envFile = config.sops.secrets."gluetun/env".path;
        };
        qbittorrent.envFile = config.sops.secrets."qbittorrent/env".path;
      };
      traefik = {
        enable = true;
        domain = "mydomain.com";
        envFile = config.sops.secrets."traefik/env".path;
        geoblock.allowedCountries = ["DE"];
      };
      uptime-kuma.enable = true;
      wg-easy = {
        enable = true;
        envFile = config.sops.secrets."wg-easy/env".path;
      };
    };
  };
}
