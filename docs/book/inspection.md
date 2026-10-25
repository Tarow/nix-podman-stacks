# Inspecting stacks

To improve discoverability of the generated container setups, you can use `nps-inspect` to view the resolved configuration of your stacks.

Run it from your configuration flake's directory:

```sh
nix run github:Tarow/nix-podman-stacks#inspect -- .#homeConfigurations.myhost
```

Use `--stack` to inspect one stack, or `--format` to choose summary, JSON, or Graphviz DOT output:

```sh
nix run github:Tarow/nix-podman-stacks#inspect -- .#homeConfigurations.myhost --stack paperless
nix run github:Tarow/nix-podman-stacks#inspect -- .#homeConfigurations.myhost --format json
nix run github:Tarow/nix-podman-stacks#inspect -- .#homeConfigurations.myhost --stack paperless --format dot > paperless.dot
```

To render the graph as an image, use Graphviz:

```sh
dot -Tsvg paperless.dot -o paperless.svg
```

The inspector shows evaluated configuration, not runtime status or generated Quadlet/systemd files. Output is not redacted.
You can also query the model directly with `nix eval`, without building the inspector package:

```sh
nix eval .#homeConfigurations.myhost.config.nps.inspection.data --json
```
