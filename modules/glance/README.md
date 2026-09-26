Highly customizable dashboard

- [Github](https://github.com/glanceapp/glance)

## Example

```nix
{config, ...}: {
  nps.stacks.glance = {
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

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.glance\.(?!containers($|\.)).*/" />

## Container Extension

Glance adds the `glance` container options to the existing `services.podman.containers.<name>` options.
Setting the `category` automatically adds the container to a `docker-containers` widget on the dashboard.

Metadata that is shared with Homepage is configured via the `dashboard` container option,
`category`, `name`, `url` as well as the `description`, `icon`, `id` and `parent` settings
are derived from it. Glance specific settings can be added via the freeform `glance` attributes,
see <https://github.com/glanceapp/glance/blob/main/docs/configuration.md#docker-containers>.

To hide a service from the dashboard, set the `dashboard.category` option to `null`,
or `glance.category` to only hide it on Glance.

Example:

```nix
{config, ...}: {
  nps.stacks.glance.enable = true;

  # Shared with Homepage
  nps.stacks.streaming.containers.jellyfin.dashboard = {
    category = "Media";
    name = "Jellyfin";
    description = "Media Server";
    icon = "di:jellyfin";
  };

  # Glance only
  nps.stacks.streaming.containers.jellyfin.glance.icon = "si:jellyfin";
}
```

Icons are written in the Glance syntax and translated for Homepage,
`di:jellyfin` becomes `jellyfin` and `sh:jellyfin` becomes `sh-jellyfin` on Homepage.

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.dashboard(\..*)?/" />

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.glance(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.glance\.containers\..*/" />
