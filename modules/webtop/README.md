Containers containing full desktop environments

- [Github](https://github.com/linuxserver/docker-webtop)

## Example

```nix
{
  nps.stacks.webtop = {
    enable = true;

    containers.webtop = {
      devices = ["/dev/dri/renderD128:/dev/dri/renderD128"];
      environment.DRINODE = "/dev/dri/renderD128";
    };
  };
}
```
