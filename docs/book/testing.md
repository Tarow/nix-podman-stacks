# Integration Tests

Every stack in this repository ships a NixOS VM integration test that deploys the stack
like a real installation and waits for all of its containers to reach a stable
`active (running)` state. The scaffolding behind those tests is exported as the `lib`
flake output, so you can run the same kind of test against **your own** configuration.

```nix
{
  inputs.nix-podman-stacks.url = "github:Tarow/nix-podman-stacks";

  outputs = { nixpkgs, nix-podman-stacks, ... }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    integrationTests.${system}.myhost = nix-podman-stacks.lib.mkIntegrationTest {
      inherit pkgs;
      name = "myhost-integration";
      modules = [./stacks.nix];
    };
  };
}
```

Run it with:

```sh
nix build .#integrationTests.x86_64-linux.myhost --option sandbox false
```

::: warning
The VM needs network access, so the Nix sandbox has to be disabled with
`--option sandbox false`. Tests are Linux-only and take a few minutes each, since the
containers are pulled inside the VM.
:::

## What the flake exports

| Output              | Purpose                                                                                               |
| ------------------- | ----------------------------------------------------------------------------------------------------- |
| `mkIntegrationTest` | Builds the VM test from a list of Home Manager modules                                                |
| `stackTestModules`  | Test modules keyed by test name, e.g. `stackTestModules.authelia` or `stackTestModules.mealie-no-oidc` |

### Options of `mkIntegrationTest`

| Option               | Type                  | Default             | Description                                                       |
| -------------------- | --------------------- | ------------------- | ----------------------------------------------------------------- |
| `pkgs`               | attrset               | required            | `nixpkgs.legacyPackages.<system>` of a Linux system               |
| `name`               | string                | `"nps-integration"` | Test name, also used as derivation name                           |
| `modules`            | list                  | `[]`                | Home Manager modules for the test user                            |
| `extraSpecialArgs`   | attrset               | `{}`                | Extra module arguments for the test user                          |
| `extraNixosModules`  | list                  | `[]`                | Extra NixOS modules, imported after the base                      |
| `expectedUnits`      | `null \| list of str` | `null`              | `null` derives them from the containers, `[]` skips the check      |
| `extraExpectedUnits` | list of str           | `[]`                | Appended to the unit list                                          |
| `extraTestScript`    | string                | `""`                | Python run after the unit check passed                            |
| `testScript`         | `null \| string`      | `null`              | Replaces the driver, including the unit check                     |
| `memorySize`         | `null \| int`         | `null`              | VM RAM in MiB. `null` uses `npsTests.memorySize` (2048)            |
| `diskSize`           | int                   | `8192`              | VM disk size in MiB                                               |
| `waitTimeout`        | int                   | `600`               | Seconds **all** units share to become active, not per unit         |
| `stabilityGrace`     | int                   | `60`                | Seconds a running unit must stay up without restarting             |
| `globalTimeout`      | `null \| int`         | `null`              | Driver timeout, derived from the two timeouts when `null`          |

## Multiple scenarios per stack

Every stack in this repository ships a default scenario in
`modules/<stack>/vm-tests/default.nix`, which becomes the `<stack>-integration` test.
Additional files in that directory become separate tests:

| File                                      | Test                             |
| ----------------------------------------- | -------------------------------- |
| `modules/<stack>/vm-tests/default.nix`    | `<stack>-integration`            |
| `modules/<stack>/vm-tests/<scenario>.nix` | `<stack>-<scenario>-integration` |

For example, `modules/mealie/vm-tests/no-oidc.nix` adds
`mealie-no-oidc-integration`. A scenario is a regular Home Manager module; import
`./default.nix` to reuse the default configuration and override what differs:

```nix
# modules/blocky/vm-tests/custom-settings.nix
{...}: {
  imports = [./default.nix];
  nps.stacks.blocky.settings = {
    # ...
  };
}
```

Run a scenario like any other test:

```sh
nix build .#integrationTests.x86_64-linux.mealie-no-oidc-integration --option sandbox false
```

`lib.stackTestModules` is keyed by test name, so both the default and the scenario are
available to consumers:

```nix
modules = [nix-podman-stacks.lib.stackTestModules.mealie-no-oidc];
```

## Your own test

`mkIntegrationTest` activates the given modules for a throwaway `ci` user and verifies
that every container comes up and stays up. Pass your config, then a module for whatever
you want to check differently:

```nix
integrationTests.${system}.microbin = nix-podman-stacks.lib.mkIntegrationTest {
  inherit pkgs;
  name = "microbin-integration";
  modules = [
    ({lib, dummySecretFile, ...}: {
      nps.stacks.microbin = {
        enable = true;
        # test an older build than the pinned default
        containers.microbin.image = lib.mkForce "ghcr.io/danielszabo99/microbin:v2.1.4";
        extraEnv = {
          MICROBIN_ADMIN_USERNAME = "admin";
          MICROBIN_ADMIN_PASSWORD.fromFile = dummySecretFile;
          MICROBIN_UPLOADER_PASSWORD.fromFile = dummySecretFile;
        };
      };
    })
  ];
  extraTestScript = ''
    machine.wait_for_open_port(8080)
  '';
};
```

Secrets are yours to provide, via sops-nix, agenix or `pkgs.writeText`, or you can use the
inert `dummy*` arguments the test user already gets: `dummySecretFile`,
`dummyClientSecretHash`, `dummyUser`, `dummyEmail`. Anything the helper sets can be
overridden with `lib.mkForce` in one of your own modules, for example the domain Traefik
and the OIDC URLs derive from:

```nix
({lib, ...}: {
  nps.stacks.traefik.domain = lib.mkForce "my.example";
})
```

A memory hungry stack raises `npsTests.memorySize` in its own test module.

## Combining with the bundled test modules

`stackTestModules` contains the test modules of every stack in this repository (the
default scenario plus any additional ones), keyed by test name, so an OIDC deployment
can reuse the Traefik and Authelia setup instead of rebuilding it. Pick
a stack whose OIDC is configured declaratively: `oidc.enable = true` writes the app's
own provider config, while `oidc.registerClient = true` (e.g. `memos`) only registers the
client in Authelia and leaves the rest to the app's web UI.

```nix
modules = [
  # brings Traefik with a self-signed cert, plus lldap
  nix-podman-stacks.lib.stackTestModules.authelia
  ({dummyClientSecretHash, dummyEmail, dummySecretFile, dummyUser, ...}: {
    nps.stacks.paperless = {
      enable = true;
      adminProvisioning = {
        username = dummyUser;
        email = dummyEmail;
        passwordFile = dummySecretFile;
      };
      oidc = {
        enable = true;
        clientSecretFile = dummySecretFile;
        clientSecretHash = dummyClientSecretHash;
      };
      secretKeyFile = dummySecretFile;
      db.passwordFile = dummySecretFile;
      extraEnv.PAPERLESS_OCR_LANGUAGES = "eng deu";
    };
  })
];
```
