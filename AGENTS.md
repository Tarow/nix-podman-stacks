# Agent Guidelines for nix-podman-stacks

Declarative Podman Quadlet management using Home Manager and Nix.

## Build/Lint/Test Commands

### Format Code

```bash
nix fmt .
```

### Validate Flake

```bash
nix flake check --keep-going
```

### Build Configurations

```bash
# Full CI config (tests all stacks)
nix build .#homeConfigurations.ci.activationPackage

# Template config
nix build ./template#homeConfigurations.myhost.activationPackage

# Documentation
nix build .#packages.x86_64-linux.book
nix build .#packages.x86_64-linux.search
```

## Module Structure

Every module (`modules/<name>/default.nix`) follows this pattern:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "modulename";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
  # category, description, displayName for Homepage/Glance
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    # ... options
  };

  config = lib.mkIf cfg.enable {
    # Configuration
  };
}
```

## Container Configuration Patterns

### Traefik & Network

- `traefik.name = name` - **only on routable** (web-facing) containers
- `stack = name` - **all containers** in a stack share a Podman network
- `dependsOnContainer` / `wantsContainer` for container dependencies

### Dashboard Configs

- `homepage` - **only on main container** (the one with `traefik.name`)
- `glance` - **all containers**; use `parent = name` for child containers (DB, Redis, etc.)
- Define let variables (name, category, displayName, description) and apply to Homepage and Glance configs

### Volume Abstraction

Use `volumeMap` attrset (not `volumes` list) for easier single-entry override:

```nix
volumeMap = {
  data = "${storage}/data:/data";
  config = "${storage}/config:/config";
};
```

## OIDC Patterns

**With claim-based admin mapping** (services support admin role via groups):

```nix
oidc = {
  enable = lib.mkOption { ... };
  clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
  clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash ...;
  adminGroup = lib.mkOption { default = "${name}_admin"; ... };
  userGroup = lib.mkOption { default = "${name}_user"; ... };
};
```

**UserGroup only** (service doesn't support admin role mapping):

```nix
oidc = {
  enable = lib.mkOption { ... };
  clientSecretFile = ...;
  clientSecretHash = ...;
  userGroup = lib.mkOption { default = "${name}_user"; ... };
  # No adminGroup - service only checks user membership
};
```

## Database Patterns

**Simple** (single DB type, e.g., SQLite or external):

```nix
db.passwordFile = lib.mkOption { type = lib.types.path; ... };
```

**Full** (sqlite/postgres choice):

```nix
db = {
  type = lib.mkOption { type = lib.types.enum ["sqlite" "postgres"]; default = "sqlite"; ... };
  username = lib.mkOption { default = name; ... };  # postgres only
  passwordFile = lib.mkOption { type = lib.types.path; ... };
};
```

## Naming Conventions

- **Options**: camelCase (`enablePrometheusExport`)
- **Image tags**: stable versions only, never `latest`
- **Image registry**: prefer `ghcr.io` over `docker.io` when both are available

## Option Patterns

### Standard Option

Always include descriptions:

```nix
lib.mkOption {
  type = lib.types.str;
  description = "What this option does.";
}
```

### extraEnv Option

For services with many environment variables:

```nix
extraEnv = lib.mkOption {
  type = (import ../types.nix lib).extraEnv;
  default = {};
  description = "Extra environment variables (supports fromFile, fromTemplate, fromCommand).";
};
```

### Environment Variable Values

When setting environment variables in modules use native Nix types:

```nix
# Good - native types
environment = {
  ENABLE_FEATURE = true;      # boolean, not "true"
  MAX_CONNECTIONS = 5;        # integer, not "5"
  DEBUG_MODE = false;        # boolean, not "false"
  PG_PORT = 5432;            # integer port number
};

# Avoid - unnecessary strings
environment = {
  ENABLE_FEATURE = "true";
  MAX_CONNECTIONS = "5";
  PG_PORT = "5432";
};
```

### Config Files

For YAML/JSON configurable services:

```nix
yaml = pkgs.formats.yaml {};
settings = lib.mkOption {
  type = yaml.type;
  apply = yaml.generate "config.yml";
  description = "Service configuration";
};
```

### Shared Utilities

```nix
(import ../types.nix lib).extraEnv
(import ../authelia/options.nix lib).clientSecretFile
(import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
```

### Option Exposure Guidelines

Keep modules minimal. For details, see:

- **Secrets**: Always expose required secrets (see [Secrets Handling](#secrets-handling))
- **Database**: Expose `db.type` only when supporting multiple DB types (see [Database Patterns](#database-patterns))
- **Environment**: Expose `extraEnv` when service has a lot of configurable env vars (see [Option Patterns](#option-patterns))
- **OIDC**: Never expose Authelia URLs or internal auth settings — auto-set when OIDC enabled

## Documentation & Testing

- Update `modules/<name>/README.md` when adding options with short description, reference to Github and website (if present) and a short usage example
- Add new module to root level README.md
- Test: add to `module_list.nix` and `ci_config.nix`, then run:
  ```bash
  nix flake check --keep-going
  nix build .#homeConfigurations.ci.activationPackage
  ```

## Secrets Handling

- Use `config.sops.secrets."path/to/secret".path` for sops-nix examples
- Use `dummySecretFile` in `ci_config.nix` for CI testing
- Never commit real secrets

### Secret File Options

Always use `lib.types.path` for secret options to support reading secrets from files at runtime, e.g. from sops-nix decrypted files:

```nix
secretKeyFile = lib.mkOption {
  type = lib.types.path;
  description = "Secret key. Generate with `openssl rand -hex 16`";
};
clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
db.passwordFile = lib.mkOption { type = lib.types.path; description = "Database password file"; };
```

## Reference Modules

Use these modules as examples for implementing specific patterns:

| Module                            | Demonstrates                                 |
| --------------------------------- | -------------------------------------------- |
| `modules/example/default.nix`     | Complete module structure (the template)     |
| `modules/streaming/default.nix`   | Multi-container stack with dependencies      |
| `modules/gatus/default.nix`       | Full DB pattern (postgres/sqlite) + extraEnv |
| `modules/mealie/default.nix`      | OIDC with admin/user groups                  |
| `modules/vaultwarden/default.nix` | OIDC userGroup only (no admin mapping)       |
| `modules/paperless/default.nix`   | Full database pattern + secretKeyFile        |
| `modules/blocky/default.nix`      | Config files (YAML settings generation)      |
| `modules/aiostreams/default.nix`  | extraEnv usage patterns                      |

## Renovate Configuration

When a project has multiple related container images (e.g., app + server), add them to the "Multi-Container Projects" group in `renovate.json` so they are updated together in a single PR.
