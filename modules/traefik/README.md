Modern HTTP reverse proxy

- [Github](https://github.com/traefik/traefik)
- [Website](https://traefik.io/)

## Examples

### Simple (Cloudflare)

```nix
{config, ...}: {
  nps.stacks.traefik = {
    enable = true;

    domain = "example.com";
    # Token will be used to fetch Letsencrypt wildcard certificates automatically (DNS challenge)
    extraEnv = {
      CF_DNS_API_TOKEN.fromFile = config.sops.secrets."traefik/cf_api_token".path;
    };
  };
}
```

### With different DNS provider

```nix
{config, ...}: {
  nps.stacks.traefik = {
    enable = true;

    domain = "example.com";
    staticConfig.certificatesResolvers.letsencrypt.acme.dnsChallenge.provider = "porkbun";
    extraEnv = {
      PORKBUN_API_KEY.fromFile = config.sops.secrets."traefik/porkbun_api_key".path;
      PORKBUN_SECRET_API_KEY.fromFile = config.sops.secrets."traefik/porkbun_secret_api_key".path;
    };
  };
}
```

### With Geoblock

```nix
{config, ...}: {
  nps.stacks.traefik = {
    enable = true;

    domain = "example.com";
    extraEnv.CF_DNS_API_TOKEN.fromFile = config.sops.secrets."traefik/cf_api_token".path;

    # For exposed services, we can limit access to certain countries using a geoblock middleware
    geoblock.allowedCountries = ["DE"];
  };
}
```
