<p align="center">
   <img src="./images/nix-podman-logo.png" alt="logo" width="130"/>
</p>
<p align="center">
   <a href="https://builtwithnix.org"><img src="https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a" alt="built with nix"></a>
   <img src="https://github.com/tarow/nix-podman-stacks/actions/workflows/build.yaml/badge.svg" alt="Build"/>
   <a href="https://renovatebot.com">
   <img src="https://img.shields.io/badge/renovate-enabled-brightgreen.svg" alt="Renovate"/></a>
   <a href="https://tarow.github.io/nix-podman-stacks/docs">
   <img src="https://img.shields.io/static/v1?logo=mdbook&label=&message=Docs&color=grey" alt="📘 Docs"/></a>
   <a href="https://tarow.github.io/nix-podman-stacks/search">
   <img src="https://img.shields.io/static/v1?logo=searxng&label=&message=Option%20Search&color=grey" alt="🔍 Option Search"/></a>
</p>

# Nix Podman Stacks

<p align="center">
<img src="./images/homepage.png" alt="preview">
</p>

Collection of opinionated Podman stacks managed by [Home Manager](https://github.com/nix-community/home-manager).

The goal is to easily deploy various self-hosted projects, including a reverse proxy, dashboard and monitoring setup. Under the hood rootless Podman (Quadlets) will be used to run the containers. It works on most Linux distros including Ubuntu, Arch, Mint, Fedora & more and is not limited to NixOS.

The projects also contains integrations with Traefik, Homepage, Grafana and more. Some examples include:

- Enabling a stack will add the respective containers to Traefik and Homepage
- Enabling CrowdSec or Authelia will automatically configure necessary Traefik plugins and middlewares
- When stacks support exporting metrics, scrape configs for Prometheus can be automatically set up
- Similariy, Grafana dashboards for Traefik, Blocky & others can be automatically added
- and more ...

While most stacks can be activated by setting a single flag, some stacks require setting mandatory values, especially for secrets.
For managing secrets, projects such as [sops-nix](https://github.com/Mic92/sops-nix) or [agenix](https://github.com/ryantm/agenix) can be used, which allow you to store your secrets along with the configuration inside a single Git repository.

## Example

Simple example of how to enable Traefik (including LetsEncrypt certificates & Geoblocking), Paperless & Homepage:

```nix
{config, ...}:
{
  nps.stacks = {
    homepage.enable = true;
    paperless = {
      enable = true;
      secretKeyFile = config.sops.secrets."paperless/secret_key".path;
      db.passwordFile = config.sops.secrets."paperless/db_password".path;
    };
    traefik = {
      enable = true;
      domain = "example.com";
      geoblock.allowedCountries = ["DE"];
      extraEnv.CF_DNS_API_TOKEN.fromFile = config.sops.secrets."traefik/cf_api_token".path;
    };
  };
}
```

Services will be automatially added to Homepage and are available via the Traefik reverse proxy.

## 📔 Option Documentation

Refer to the [documentation](https://tarow.github.io/nix-podman-stacks/docs) to get a started and see a list of available options.

There is also an [Option Search](https://tarow.github.io/nix-podman-stacks/search) to easily explore existing options.

## 📦 Available Stacks

- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/adguard-home.svg" style="width:1em;height:1em;" /> [Adguard](https://tarow.github.io/nix-podman-stacks/docs/stacks/adguard.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/adventure-log.webp" style="width:1em;height:1em;" /> [AdventureLog](https://tarow.github.io/nix-podman-stacks/docs/stacks/adventurelog.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/stremio.svg" style="width:1em;height:1em;" /> [AIOStreams](https://tarow.github.io/nix-podman-stacks/docs/stacks/aiostreams.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/anchor.svg" style="width:1em;height:1em;" /> [Anchor](https://tarow.github.io/nix-podman-stacks/docs/stacks/anchor.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/audiobookshelf.svg" style="height:1em;" /> [Audiobookshelf](https://tarow.github.io/nix-podman-stacks/docs/stacks/audiobookshelf.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/authelia.svg" style="height:1em;" /> [Authelia](https://tarow.github.io/nix-podman-stacks/docs/stacks/authelia.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/baikal.png" style="width:1em;height:1em;" /> [Baikal](https://tarow.github.io/nix-podman-stacks/docs/stacks/baikal.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bentopdf.svg" style="width:1em;height:1em;" /> [BentoPDF](https://tarow.github.io/nix-podman-stacks/docs/stacks/bentopdf.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/beszel.svg" style="width:1em;height:1em;" /> [Beszel](https://tarow.github.io/nix-podman-stacks/docs/stacks/beszel.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/blocky.svg" style="width:1em;height:1em;" /> [Blocky](https://tarow.github.io/nix-podman-stacks/docs/stacks/blocky.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/booklore.webp" style="height:1em;" /> [Booklore](https://tarow.github.io/nix-podman-stacks/docs/stacks/booklore.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bytestash.svg" style="width:1em;height:1em;" /> [ByteStash](https://tarow.github.io/nix-podman-stacks/docs/stacks/bytestash.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/calibre-web.svg" style="width:1em;height:1em;" /> [Calibre-Web Automated](https://tarow.github.io/nix-podman-stacks/docs/stacks/calibre.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/changedetection.svg" style="width:1em;height:1em;" /> [Changedetection](https://tarow.github.io/nix-podman-stacks/docs/stacks/changedetection.html)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/changedetection.svg" style="width:1em;height:1em;" /> Changedetection
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/chrome.svg" style="width:1em;height:1em;" /> Sock Puppet Browser
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/crowdsec.svg" style="width:1em;height:1em;" /> [CrowdSec](https://tarow.github.io/nix-podman-stacks/docs/stacks/crowdsec.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/davis.png" style="width:1em;height:1em;" /> [Davis](https://tarow.github.io/nix-podman-stacks/docs/stacks/davis.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dawarich.svg" style="width:1em;height:1em;" /> [Dawarich](https://tarow.github.io/nix-podman-stacks/docs/stacks/dawarich.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ddns-updater.svg" style="width:1em;height:1em;" /> [DDNS-Updater](https://tarow.github.io/nix-podman-stacks/docs/stacks/ddns-updater.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/azure-dns.svg" style="width:1em;height:1em;" /> [DockDNS](https://tarow.github.io/nix-podman-stacks/docs/stacks/dockdns.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/haproxy.svg" style="width:1em;height:1em;" /> [Docker Socket Proxy](https://tarow.github.io/nix-podman-stacks/docs/stacks/docker-socket-proxy.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/donetick.svg" style="width:1em;height:1em;" /> [Donetick](https://tarow.github.io/nix-podman-stacks/docs/stacks/donetick.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dozzle.svg" style="width:1em;height:1em;" /> [Dozzle](https://tarow.github.io/nix-podman-stacks/docs/stacks/dozzle.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/ephemera.webp" style="width:1em;height:1em;" /> [Ephemera](https://tarow.github.io/nix-podman-stacks/docs/stacks/ephemera.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/filebrowser.svg" style="width:1em;height:1em;" /> [Filebrowser](https://tarow.github.io/nix-podman-stacks/docs/stacks/filebrowser.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/filebrowser-quantum.png" style="width:1em;height:1em;" /> [Filebrowser Quantum](https://tarow.github.io/nix-podman-stacks/docs/stacks/filebrowser-quantum.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/flaresolverr.svg" style="width:1em;height:1em;" /> [Flaresolverr](https://tarow.github.io/nix-podman-stacks/docs/stacks/flaresolverr.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/forgejo.svg" style="width:1em;height:1em;" /> [Forgejo](https://tarow.github.io/nix-podman-stacks/docs/stacks/forgejo.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons@master/webp/free-games-claimer.webp" style="width:1em;height:1em;" /> [Free Games Claimer](https://tarow.github.io/nix-podman-stacks/docs/stacks/free-games-claimer.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/freshrss.svg" style="width:1em;height:1em;" /> [FreshRSS](https://tarow.github.io/nix-podman-stacks/docs/stacks/freshrss.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/gatus.svg" style="width:1em;height:1em;" /> [Gatus](https://tarow.github.io/nix-podman-stacks/docs/stacks/gatus.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/glance.svg" style="width:1em;height:1em;" /> [Glance](https://tarow.github.io/nix-podman-stacks/docs/stacks/glance.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/guacamole.svg" style="width:1em;height:1em;" /> [Guacamole](https://tarow.github.io/nix-podman-stacks/docs/stacks/guacamole.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/healthchecks.svg" style="width:1em;height:1em;" /> [Healthchecks](https://tarow.github.io/nix-podman-stacks/docs/stacks/healthchecks.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/home-assistant.svg" style="width:1em;height:1em;" /> [Home Assistant](https://tarow.github.io/nix-podman-stacks/docs/stacks/homeassistant.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/homebox.svg" style="width:1em;height:1em;" /> [HomeBox](https://tarow.github.io/nix-podman-stacks/docs/stacks/homebox.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/homepage.png" style="width:1em;height:1em;" /> [Homepage](https://tarow.github.io/nix-podman-stacks/docs/stacks/homepage.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/hortusfox.webp" style="width:1em;height:1em;" /> [HortusFox](https://tarow.github.io/nix-podman-stacks/docs/stacks/hortusfox.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/immich.svg" style="width:1em;height:1em;" /> [Immich](https://tarow.github.io/nix-podman-stacks/docs/stacks/immich.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/it-tools.svg" style="width:1em;height:1em;" /> [IT-Tools](https://tarow.github.io/nix-podman-stacks/docs/stacks/it-tools.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jotty.svg" style="width:1em;height:1em;" /> [Jotty](https://tarow.github.io/nix-podman-stacks/docs/stacks/jotty.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/kaneo.webp" style="width:1em;height:1em;" /> [Kaneo](https://tarow.github.io/nix-podman-stacks/docs/stacks/kaneo.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/karakeep.svg" style="width:1em;height:1em;" /> [Karakeep](https://tarow.github.io/nix-podman-stacks/docs/stacks/karakeep.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/kimai.svg" style="width:1em;height:1em;" /> [Kimai](https://tarow.github.io/nix-podman-stacks/docs/stacks/kimai.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/kitchenowl.svg" style="width:1em;height:1em;" /> [KitchenOwl](https://tarow.github.io/nix-podman-stacks/docs/stacks/kitchenowl.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/komga.svg" style="width:1em;height:1em;" /> [Komga](https://tarow.github.io/nix-podman-stacks/docs/stacks/komga.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/leantime.svg" style="width:1em;height:1em;" /> [Leantime](https://tarow.github.io/nix-podman-stacks/docs/stacks/leantime.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/svg/lldap.svg" style="width:1em;height:1em;" /> [LLDAP](https://tarow.github.io/nix-podman-stacks/docs/stacks/lldap.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/mazanoke.webp" style="width:1em;height:1em;" /> [Mazanoke](https://tarow.github.io/nix-podman-stacks/docs/stacks/mazanoke.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/mealie.svg" style="width:1em;height:1em;" /> [Mealie](https://tarow.github.io/nix-podman-stacks/docs/stacks/mealie.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/memos.webp" style="width:1em;height:1em;" /> [Memos](https://tarow.github.io/nix-podman-stacks/docs/stacks/memos.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/microbin.png" style="width:1em;height:1em;" /> [MicroBin](https://tarow.github.io/nix-podman-stacks/docs/stacks/microbin.html)
- 🔍 [Monitoring](https://tarow.github.io/nix-podman-stacks/docs/stacks/monitoring.html)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/alloy.svg" style="width:1em;height:1em;" /> Alloy
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/grafana.svg" style="width:1em;height:1em;" /> Grafana
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/loki.svg" style="width:1em;height:1em;" /> Loki
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prometheus.svg" style="width:1em;height:1em;" /> Prometheus
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/alertmanager.svg" style="width:1em;height:1em;" /> Alertmanager
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ntfy.svg" style="width:1em;height:1em;" /> Alertmanager-ntfy
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/podman.svg" style="width:1em;height:1em;" /> Podman Metrics Exporter
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/n8n.svg" style="width:1em;height:1em;" /> [n8n](https://tarow.github.io/nix-podman-stacks/docs/stacks/n8n.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/navidrome.svg" style="width:1em;height:1em;" /> [Navidrome](https://tarow.github.io/nix-podman-stacks/docs/stacks/navidrome.html)
- <img src="https://raw.githubusercontent.com/Lissy93/networking-toolbox/main/static/icon.png" style="width:1em;height:1em;" /> [Networking Toolbox](https://tarow.github.io/nix-podman-stacks/docs/stacks/networking-toolbox.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons@main/svg/norish.svg" style="width:1em;height:1em;" /> [Norish](https://tarow.github.io/nix-podman-stacks/docs/stacks/norish.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ntfy.svg" style="width:1em;height:1em;" /> [ntfy](https://tarow.github.io/nix-podman-stacks/docs/stacks/ntfy.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/omni-tools.png" style="width:1em;" /> [OmniTools](https://tarow.github.io/nix-podman-stacks/docs/stacks/omnitools.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/outline.svg" style="width:1em;" /> [Outline](https://tarow.github.io/nix-podman-stacks/docs/stacks/outline.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pangolin.svg" style="width:1em;height:1em;" /> [Pangolin-Newt](https://tarow.github.io/nix-podman-stacks/docs/stacks/pangolin-newt.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/paperless.svg" style="width:1em;height:1em;" /> [Paperless-ngx](https://tarow.github.io/nix-podman-stacks/docs/stacks/paperless.html)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/paperless.svg" style="width:1em;height:1em;" /> Paperless-ngx
  - 📂 FTP Server
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/papra.svg" style="width:1em;" /> [Papra](https://tarow.github.io/nix-podman-stacks/docs/stacks/papra.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/romm.svg" style="width:1em;height:1em;" /> [RomM](https://tarow.github.io/nix-podman-stacks/docs/stacks/romm.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/searxng.svg" style="width:1em;height:1em;" /> [SearXNG](https://tarow.github.io/nix-podman-stacks/docs/stacks/searxng.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/calibre-web-automated-book-downloader.webp" style="width:1em;height:1em;" /> [Shelfmark](https://tarow.github.io/nix-podman-stacks/docs/stacks/shelfmark.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sshwifty.svg" style="width:1em;height:1em;" /> [Sshwifty](https://tarow.github.io/nix-podman-stacks/docs/stacks/sshwifty.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/stirling-pdf.svg" style="width:1em;height:1em;" /> [Stirling-PDF](https://tarow.github.io/nix-podman-stacks/docs/stacks/stirling-pdf.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/storyteller.webp" style="width:1em;height:1em;" /> [Storyteller](https://tarow.github.io/nix-podman-stacks/docs/stacks/storyteller.html)
- <span style="width:1em;height:1em;">📺</span> [Streaming](https://tarow.github.io/nix-podman-stacks/docs/stacks/streaming.html)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bazarr.svg" style="width:1em;height:1em;" /> Bazarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/gluetun.svg" style="width:1em;height:1em;" /> Gluetun
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyfin.svg" style="width:1em;height:1em;" /> Jellyfin
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/profilarr.svg" style="width:1em;height:1em;" /> Profilarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg" style="width:1em;height:1em;" /> Prowlarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qbittorrent.svg" style="width:1em;height:1em;" /> qBittorrent
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qui.svg" style="width:1em;height:1em;" /> qui
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/overseerr.svg" style="width:1em;height:1em;" /> Seerr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg" style="width:1em;height:1em;" /> Radarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg" style="width:1em;height:1em;" /> Sonarr
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/tandoor-recipes.svg" style="width:1em;height:1em;" /> [Tandoor](https://tarow.github.io/nix-podman-stacks/docs/stacks/tandoor.html)
- <img src="https://raw.githubusercontent.com/Templarian/MaterialDesign-SVG/master/svg/book-clock.svg" style="width:1em;height:1em;" /> [TimeTracker](https://tarow.github.io/nix-podman-stacks/docs/stacks/timetracker.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/traefik.svg" style="width:1em;height:1em;" /> [Traefik](https://tarow.github.io/nix-podman-stacks/docs/stacks/traefik.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/trek.webp" style="height:1em;" /> [Trek](https://tarow.github.io/nix-podman-stacks/docs/stacks/trek.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/trip.webp" style="height:1em;" /> [Trip](https://tarow.github.io/nix-podman-stacks/docs/stacks/trip.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/uptime-kuma.svg" style="width:1em;height:1em;" /> [Uptime-Kuma](https://tarow.github.io/nix-podman-stacks/docs/stacks/uptime-kuma.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/vaultwarden.svg" style="width:1em;height:1em;" /> [Vaultwarden](https://tarow.github.io/nix-podman-stacks/docs/stacks/vaultwarden.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/vikunja.svg" style="width:1em;height:1em;" /> [Vikunja](https://tarow.github.io/nix-podman-stacks/docs/stacks/vikunja.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/wallos.webp" style="width:1em;height:1em;" /> [Wallos](https://tarow.github.io/nix-podman-stacks/docs/stacks/wallos.html)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/watchstate.webp" style="width:1em;height:1em;" /> [WatchState](https://tarow.github.io/nix-podman-stacks/docs/stacks/watchstate.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/webtop.webp" style="width:1em;height:1em;" /> [Webtop](https://tarow.github.io/nix-podman-stacks/docs/stacks/webtop.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/wireguard.svg" style="width:1em;height:1em;" /> [wg-easy](https://tarow.github.io/nix-podman-stacks/docs/stacks/wg-easy.html)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/wireguard.svg" style="width:1em;height:1em;" /> [wg-portal](https://tarow.github.io/nix-podman-stacks/docs/stacks/wg-portal.html)
- <img src="https://repository-images.githubusercontent.com/16027367/5e148d00-d9f9-11e9-8fa7-04b02283d9af" style="width:1em;height:1em;" /> [Yopass](https://tarow.github.io/nix-podman-stacks/docs/stacks/yopass.html)

## 💡 Missing a Stack / Option / Integration ?

Is your favorite self-hosted app not included yet? Or would you like to see additional options or integrations?
I'm always looking to expand the collection!
Feel free to [open an issue](https://github.com/Tarow/nix-podman-stacks/issues) or contribute directly with a [pull request](https://github.com/Tarow/nix-podman-stacks/pulls).

When contributing a new service/stack, you can refer to the [example](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/example) stack as a starting point.
