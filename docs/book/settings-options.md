# Base Settings

<script setup>
import { data } from "./nps.data.ts";
import { RenderDocs } from "easy-nix-documentation";
</script>

Most stacks will rely on some central settings.
An example would be the base location where containers should create bind mounts for persistent data.

## Example

```nix
{config, ...}: {
  nps = {
    hostIP4Address = "192.168.178.2";
    hostUid = 1000;
    storageBaseDir = "${config.home.homeDirectory}/stacks";
    externalStorageBaseDir = "/mnt/hdd";
  };
}
```

## Options

<RenderDocs :options="data" :exclude="/nps\.stacks\.*|nps\.containers\.*|services\.podman\.*/" />
