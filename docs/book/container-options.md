# Container Options

This project extends Home Managers existing [`services.podman.containers`](https://home-manager-options.extranix.com/?query=services.podman.containers&release=master) options, to provide additional abstractions for example for Traefik or Homepage.

While you won't need to set any of those to get the stacks up and running, they can be useful when customizing settings.

The options can be set directly on `services.podman.container` level, or through the stack aliases provided with this project.
For example, the following two configurations are equivalent:

```nix
nps.stacks = {
    streaming.containers.jellyfin.expose = true;
};
```

```nix
services.podman.containers.jellyfin.expose = true;
```

The following list contains all extension options that will be added by this project.

---

<script setup>
import { data } from "./nps.data.ts";
import { RenderDocs } from "easy-nix-documentation";
</script>

<RenderDocs :options="data" :include="/services\.podman\.containers\.+\.*/" />
