lib: domain: network:
let
  mkRedirect = to: {
    address = ":80";
    http = {
      redirections = {
        entryPoint = {
          to = to;
          scheme = "https";
        };
      };
    };
  };
in
{
  entryPoints = rec {
    web = mkRedirect "websecure";

    web-internal = mkRedirect "websecure-internal";

    # Used with Socket Activation
    websecure = {
      asDefault = true;
      address = ":443";
      http = {
        tls = {
          certResolver = "letsencrypt";
          domains = [
            {
              main = domain;
              sans = [ "*.${domain}" ];
            }
          ];
        };
      };
    };

    # Used with podman network internal connections
    websecure-internal = websecure;
  };
  serversTransport = {
    insecureSkipVerify = true;
  };
  api = {
    dashboard = true;
  };
  providers = {
    docker = {
      exposedByDefault = false;
      network = network;
      defaultRule = "Host(`{{ coalesce (index .Labels \"com.docker.compose.service\") (normalize .Name) }}.${domain}`)";
    };
    file = {
      directory = "/dynamic";
      watch = true;
    };
  };
  certificatesResolvers = {
    letsencrypt = {
      acme = {
        email = "mail@${domain}";
        storage = "/letsencrypt/acme.json";
        dnsChallenge = {
          provider = lib.mkDefault "cloudflare";
          resolvers = [
            "1.1.1.1:53"
            "8.8.8.8:53"
          ];
        };
      };
    };
  };
  experimental = {
    plugins = {
      geoblock = {
        moduleName = "github.com/nscuro/traefik-plugin-geoblock";
        version = "v0.14.0";
      };
    };
  };
  accessLog = {
    format = "json";
  };
  log = {
    level = "WARN";
  };
}
