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

- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/adguard-home.svg" style="width:1em;height:1em;" /> [Adguard](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/adguard/default.nix)

- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/stremio.svg" style="width:1em;height:1em;" /> [AIOStreams](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/aiostreams/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/audiobookshelf.svg" style="height:1em;" /> [Audiobookshelf](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/audiobookshelf/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/authelia.svg" style="height:1em;" /> [Authelia](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/authelia/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/baikal.png" style="width:1em;height:1em;" /> [Baikal](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/baikal/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bentopdf.svg" style="width:1em;height:1em;" /> [BentoPDF](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/bentopdf/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/beszel.svg" style="width:1em;height:1em;" /> [Beszel](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/beszel/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/blocky.svg" style="width:1em;height:1em;" /> [Blocky](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/blocky/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/booklore.webp" style="height:1em;" /> [Booklore](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/booklore/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bytestash.svg" style="width:1em;height:1em;" /> [ByteStash](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/bytestash/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/calibre-web.svg" style="width:1em;height:1em;" /> [Calibre-Web](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/calibre/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/calibre-web.svg" style="width:1em;height:1em;" /> Calibre-Web Automated
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/calibre-web-automated-book-downloader.png" style="width:1em;height:1em;" /> Calibre-Web Automated Book Downloader
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/changedetection.svg" style="width:1em;height:1em;" /> [Changedetection](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/changedetection/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/changedetection.svg" style="width:1em;height:1em;" /> Changedetection
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/chrome.svg" style="width:1em;height:1em;" /> Sock Puppet Browser
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/crowdsec.svg" style="width:1em;height:1em;" /> [CrowdSec](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/crowdsec/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/davis.png" style="width:1em;height:1em;" /> [Davis](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/davis/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/azure-dns.svg" style="width:1em;height:1em;" /> [DockDNS](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/dockdns/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/haproxy.svg" style="width:1em;height:1em;" /> [Docker Socket Proxy](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/docker-socket-proxy/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/donetick.svg" style="width:1em;height:1em;" /> [Donetick](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/donetick/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/dozzle.svg" style="width:1em;height:1em;" /> [Dozzle](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/dozzle/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/ephemera.webp" style="width:1em;height:1em;" /> [Ephemera](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/ephemera/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/filebrowser.svg" style="width:1em;height:1em;" /> [Filebrowser](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/filebrowser/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/filebrowser-quantum.png" style="width:1em;height:1em;" /> [Filebrowser Quantum](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/filebrowser-quantum/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/flaresolverr.svg" style="width:1em;height:1em;" /> [Flaresolverr](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/flaresolverr/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/forgejo.svg" style="width:1em;height:1em;" /> [Forgejo](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/forgejo/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons@master/webp/free-games-claimer.webp" style="width:1em;height:1em;" /> [Free Games Claimer](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/free-games-claimer/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/freshrss.svg" style="width:1em;height:1em;" /> [FreshRSS](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/freshrss/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/gatus.svg" style="width:1em;height:1em;" /> [Gatus](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/gatus/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/glance.svg" style="width:1em;height:1em;" /> [Glance](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/glance/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/guacamole.svg" style="width:1em;height:1em;" /> [Guacamole](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/guacamole/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/healthchecks.svg" style="width:1em;height:1em;" /> [Healthchecks](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/healchecks/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/home-assistant.svg" style="width:1em;height:1em;" /> [Home Assistant](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/homeassistant/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/homepage.png" style="width:1em;height:1em;" /> [Homepage](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/homepage/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/hortusfox.webp" style="width:1em;height:1em;" /> [HortusFox](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/hortusfox/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/immich.svg" style="width:1em;height:1em;" /> [Immich](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/immich/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/it-tools.svg" style="width:1em;height:1em;" /> [IT-Tools](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/it-tools/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jotty.svg" style="width:1em;height:1em;" /> [Jotty](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/jotty/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/karakeep.svg" style="width:1em;height:1em;" /> [Karakeep](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/karakeep/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/kimai.svg" style="width:1em;height:1em;" /> [Kimai](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/kimai/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/kitchenowl.svg" style="width:1em;height:1em;" /> [KitchenOwl](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/kitchenowl/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/komga.svg" style="width:1em;height:1em;" /> [Komga](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/komga/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/svg/lldap.svg" style="width:1em;height:1em;" /> [LLDAP](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/lldap/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/mazanoke.webp" style="width:1em;height:1em;" /> [Mazanoke](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/mazanoke/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/mealie.svg" style="width:1em;height:1em;" /> [Mealie](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/mealie/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/memos.webp" style="width:1em;height:1em;" /> [Memos](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/memos/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/microbin.png" style="width:1em;height:1em;" /> [MicroBin](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/microbin/default.nix)
- 🔍 [Monitoring](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/monitoring/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/alloy.svg" style="width:1em;height:1em;" /> Alloy
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/grafana.svg" style="width:1em;height:1em;" /> Grafana
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/loki.svg" style="width:1em;height:1em;" /> Loki
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prometheus.svg" style="width:1em;height:1em;" /> Prometheus
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/alertmanager.svg" style="width:1em;height:1em;" /> Alertmanager
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ntfy.svg" style="width:1em;height:1em;" /> Alertmanager-ntfy
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/podman.svg" style="width:1em;height:1em;" /> Podman Metrics Exporter
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/n8n.svg" style="width:1em;height:1em;" /> [n8n](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/n8n/default.nix)
- <img src="https://raw.githubusercontent.com/Lissy93/networking-toolbox/main/static/icon.png" style="width:1em;height:1em;" /> [Networking Toolbox](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/networking-toolbox/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons@main/svg/norish.svg" style="width:1em;height:1em;" /> [Norish](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/norish/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/ntfy.svg" style="width:1em;height:1em;" /> [ntfy](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/ntfy/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/omni-tools.png" style="width:1em;" /> [OmniTools](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/omnitools/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/outline.svg" style="width:1em;" /> [Outline](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/outline/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pangolin.svg" style="width:1em;height:1em;" /> [Pangolin-Newt](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/pangolin-newt/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/paperless.svg" style="width:1em;height:1em;" /> [Paperless-ngx](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/paperless/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/paperless.svg" style="width:1em;height:1em;" /> Paperless-ngx
  - 📂 FTP Server
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/pocket-id.svg" style="width:1em;height:1em;" /> [Pocket ID](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/pocket-id/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/romm.svg" style="width:1em;height:1em;" /> [RomM](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/romm/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sshwifty.svg" style="width:1em;height:1em;" /> [Sshwifty](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/sshwifty/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/stirling-pdf.svg" style="width:1em;height:1em;" /> [Stirling-PDF](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/stirling-pdf/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/selfhst/icons/webp/storyteller.webp" style="width:1em;height:1em;" /> [Storyteller](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/storyteller/default.nix)
- <span style="width:1em;height:1em;">📺</span> [Streaming](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/streaming/default.nix)
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bazarr.svg" style="width:1em;height:1em;" /> Bazarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/gluetun.svg" style="width:1em;height:1em;" /> Gluetun
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyfin.svg" style="width:1em;height:1em;" /> Jellyfin
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg" style="width:1em;height:1em;" /> Prowlarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qbittorrent.svg" style="width:1em;height:1em;" /> qBittorrent
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg" style="width:1em;height:1em;" /> Radarr
  - <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg" style="width:1em;height:1em;" /> Sonarr
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/tandoor-recipes.svg" style="width:1em;height:1em;" /> [Tandoor](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/tandoor/default.nix)
- <img src="https://raw.githubusercontent.com/Templarian/MaterialDesign-SVG/master/svg/book-clock.svg" style="width:1em;height:1em;" /> [TimeTracker](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/timetracker/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/traefik.svg" style="width:1em;height:1em;" /> [Traefik](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/traefik/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/uptime-kuma.svg" style="width:1em;height:1em;" /> [Uptime-Kuma](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/uptime-kuma/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/vaultwarden.svg" style="width:1em;height:1em;" /> [Vaultwarden](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/vaultwarden/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/vikunja.svg" style="width:1em;height:1em;" /> [Vikunja](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/vikunja/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/webtop.webp" style="width:1em;height:1em;" /> [Webtop](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/webtop/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/wireguard.svg" style="width:1em;height:1em;" /> [wg-easy](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/wg-easy/default.nix)
- <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/wireguard.svg" style="width:1em;height:1em;" /> [wg-portal](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/wg-portal/default.nix)
- <img src="https://repository-images.githubusercontent.com/16027367/5e148d00-d9f9-11e9-8fa7-04b02283d9af" style="width:1em;height:1em;" /> [Yopass](https://github.com/Tarow/nix-podman-stacks/tree/main/modules/yopass/default.nix)

## 💡 Missing a Stack / Option / Integration ?

Is your favorite self-hosted app not included yet? Or would you like to see additional options or integrations?
I'm always looking to expand the collection!
Feel free to [open an issue](https://github.com/Tarow/nix-podman-stacks/issues) or contribute directly with a [pull request](https://github.com/Tarow/nix-podman-stacks/pulls).
