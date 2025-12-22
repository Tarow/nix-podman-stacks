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
