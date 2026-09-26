Customizable application dashboard

- [Github](https://github.com/gethomepage/homepage)
- [Website](https://gethomepage.dev/)

## Example

```nix
{
  nps.stacks.homepage = {
    enable = true;

    containers.homepage.volumes = [
      "/hostpath/to/image:/app/public/images/background.jpg"
    ];
    settings.background = {
      image = "/images/background.jpg";
      opacity = 50;
    };
    widgets = [
      {
        openweathermap = {
          units = "metric";
          cache = 5;
          apiKey.path = config.sops.secrets."OPENWEATHERMAP_API_KEY".path;
        };
      }
    ];
  };
}
```

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.homepage\.(?!containers($|\.)).*/" />

## Container Extension

Homepage adds the `homepage` container options to the existing `services.podman.containers.<name>` options.
Setting the `category` automatically adds the container to the Homepage dashboard under that category.

Metadata that is shared with Glance is configured via the `dashboard` container option,
`category` and `name` as well as the `href`, `description` and `icon` settings are derived from it.
Homepage specific settings such as the widget configuration are added via the `settings` attribute,
see <https://gethomepage.dev/configs/services/>.

To hide a service from the dashboard, set the `dashboard.category` option to `null`,
or `homepage.category` to only hide it on Homepage.

Example:

```nix
{config, ...}: {
  nps.stacks.homepage.enable = true;

  # Shared with Glance
  nps.stacks.streaming.containers.jellyfin.dashboard = {
    category = "Media";
    name = "Jellyfin";
    description = "Media Server";
    icon = "di:jellyfin";
  };

  # Homepage only
  nps.stacks.streaming.containers.jellyfin.homepage.settings.widget.enable = true;
}
```

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.dashboard(\..*)?/" />

<RenderDocs :options="data" :include="/services\.podman\.containers\..+\.homepage(\..*)?/" />

## Container Aliases

<RenderDocs :options="data" :include="/nps\.stacks\.homepage\.containers\..*/" />
