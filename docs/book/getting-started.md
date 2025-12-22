# Getting Started

## ⚙️ Prerequisites

- [Nix Installation](https://nixos.org/download/#nix-install-linux)
- `net.ipv4.ip_unprivileged_port_start=0` or any other way of allowing non-root processes to bind to ports below 1024

## 🚀 Setup

If you already have an existing flake setup, add this projects flake as an input and include the flake output `homeModules.nps` in your Home Manager modules.
Refer to the [Options](./settings-options) and [Examples](./examples.md) to explore available settings.

---

If you don't use Nix yet, you can use the projects template to get started:

```sh
nix flake init --template github:Tarow/nix-podman-stacks
```

Make sure to go through the `flake.nix`, `stacks.nix` & `sops.nix` files and adapt options as needed.
Also make sure to generate your own encryption age key and encrypt your secrets with it!

To apply your configuration, run:

```sh
nix run home-manager -- switch --experimental-features "nix-command flakes pipe-operators" -b bak --flake .#myhost
```

The template includes an example configuration of the following setup:

- Authelia as an OIDC provider with LLDAP as the user backend
- Immich & Paperless with OIDC login pre-configured
- Traefik as a reverse proxy including a Geoblocking middleware. Wildcard certificates will be fetched from Let's Encrypt (DNS Challenge).
- CrowdSec including a Traefik middleware setup
- Blocky as DNS proxy
- Monitoring stack with Alloy, Loki, Grafana & Prometheus. Comes with Grafana dashboards for Traefik & Blocky
- All services are added to the Homepage dashboard
- Podman Socket Access through a read-only proxy
- Secrets are provisioned by sops-nix

A basic overview of the templates architecture will look like this:

<p align="center">
<img src="./images/template-overview.excalidraw.svg" width="512" alt="template-overview">
</p>
