# Builds a NixOS VM integration test for a single stack.
#
# Usage (from `flake.nix`):
#
#   (import ./tests/vm.nix { inherit pkgs home-manager; }) "it-tools"
#
# The VM boots with the base setup from `base-config.nix`/`base-home.nix`
# merged with `modules/<stack>/vm-test.nix`, activates it like a real
# deployment and verifies that all systemd user services of the stack are
# running (see `check.sh` / `driver.py`).
{
  pkgs,
  home-manager,
  self,
  ...
}: stackName:
pkgs.testers.runNixOSTest {
  name = "${stackName}-integration";
  globalTimeout = 1800;

  nodes.machine = {
    config,
    lib,
    ...
  }: {
    imports = [
      (import ./base-config.nix {
        inherit
          home-manager
          pkgs
          self
          ;
        stackTestModule = ../modules/${stackName}/vm-test.nix;
      })
    ];

    # Expected container units, derived from the evaluated configuration.
    environment.etc."nps-test/expected-units".text = lib.concatStringsSep "\n" (
      map (name: "podman-${name}.service") (lib.attrNames config.home-manager.users.ci.services.podman.containers)
    );
  };

  testScript = builtins.readFile ./driver.py;
}
