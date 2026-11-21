# Public helpers, exported as the `lib` flake output. Mainly `mkIntegrationTest`, which
# lets consumers run this repository's own kind of integration test against their own
# configuration. Docs: docs/book/testing.md
{
  self,
  home-manager,
  lib,
}: let
  scenarios = import ../tests/scenarios.nix {inherit lib;};
in {
  # Activates Home Manager modules as the `ci` user in a VM and verifies that all
  # stack services reach a stable `active (running)` state.
  mkIntegrationTest = import ../tests/mk-integration-test.nix {
    inherit
      home-manager
      self
      ;
  };

  # Test modules keyed by test name: the stack name for the default scenario and
  # `<stack>-<scenario>` for additional ones, e.g. `stackTestModules.mealie-no-oidc`.
  stackTestModules = scenarios.testModules;
}
