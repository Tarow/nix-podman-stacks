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
