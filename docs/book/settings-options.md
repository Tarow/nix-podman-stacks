# Settings

<script setup>
import { data } from "./nps.data.ts";
import { RenderDocs } from "easy-nix-documentation";
</script>

Most stacks will rely on some central settings.
An example would be the base location where containers should create bind mounts for persistent data.

The following list contains all of the central settings.
<br/><br/>

## NPS Options

<RenderDocs :options="data" :exclude="/nps\.stacks\.*|nps\.containers\.*|services\.podman\.*/" />
