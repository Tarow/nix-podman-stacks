Highly customizable dashboard with dynamic updates

- [Github](https://github.com/Panonim/dynacat)
- [Documentation](https://dynacat.artur.zone/)

## Example

```nix
{config, ...}: {
  nps.stacks.dynacat = {
    enable = true;
    settings.pages.home = {
      columns.start = {
        rank = 500;
        size = "small";
        widgets = [
          {
            type = "server-stats";
            servers = [
              {
                type = "local";
                name = "Server";
              }
            ];
          }
          {
            type = "reddit";
            subreddit = "selfhosted";
            collapse-after = 3;
          }
        ];
      };
    };
  };
}
```

## With OIDC

```nix
{config, ...}: {
  nps.stacks.dynacat = {
    enable = true;
    secretKeyFile = config.sops.secrets."dynacat/secret_key".path;
    oidc = {
      enable = true;
      clientSecretFile = config.sops.secrets."dynacat/authelia_client_secret".path;
    };
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.dynacat\.(?!containers($|\.)).*/" />

## Container Extension

Dynacat adds the `dynacat` container options to the existing `services.podman.containers.<name>` options.
Setting the `category` automatically adds the container to a `docker-containers` widget on the dashboard.

Metadata that is shared between the dashboards is configured via the `dashboard` container option,
`category`, `name`, `url` as well as the `description`, `icon`, `id` and `parent` settings
are derived from it. Dynacat specific settings can be added via the freeform `dynacat` attributes,
see <https://dynacat.artur.zone/#configuration/docker-containers>.

To hide a service from the dashboard, set the `dashboard.category` option to `null`,
or `dynacat.category` to only hide it on Dynacat.

Example:

```nix
{config, ...}: {
  nps.stacks.dynacat.enable = true;

  # Shared between the dashboards
  nps.stacks.streaming.containers.jellyfin.dashboard = {
    category = "Media";
    name = "Jellyfin";
    description = "Media Server";
    icon = "di:jellyfin";
  };

  # Dynacat only
  nps.stacks.streaming.containers.jellyfin.dynacat.icon = "si:jellyfin";
}
```

Icons are written in the Dynacat syntax, see the `dashboard.icon` option for the available prefixes.

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.dashboard(\..*)?/" />

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.dynacat(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.dynacat\.containers\..*/" />
