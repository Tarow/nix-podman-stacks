## Example

```nix
{
  nps.stacks.free-games-claimer = {
    enable = true;
    containers.free-games-claimer.exec = "node epic-games";
  };
}
```

## About

- A free game claimer (Epic Games, GOG, etc.)
- [Github](https://github.com/vogler/free-games-claimer)