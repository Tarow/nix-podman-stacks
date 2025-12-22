## Example

```nix
{
  webtop = {
    enable = true;

    containers.webtop = {
      devices = ["/dev/dri/renderD128:/dev/dri/renderD128"];
      environment.DRINODE = "/dev/dri/renderD128";
    };
  };
}
```
