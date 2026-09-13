# Builds a NixOS VM integration test for a single stack.
# See tests/check.sh and tests/driver.py for the verification logic.
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
