# Enumerates the integration test scenarios of the stacks.
#
# Every stack ships `modules/<stack>/vm-tests/default.nix`, the default scenario
# that becomes the `<stack>-integration` test. Any other
# `modules/<stack>/vm-tests/<scenario>.nix` file becomes
# `<stack>-<scenario>-integration`.
{lib}: let
  modulesDir = ../modules;
  stackNames = builtins.attrNames (import ../modules/module_list.nix);
  entries = builtins.readDir modulesDir;

  # `module_list.nix` also contains file entries (settings, inspection).
  stackDirs =
    builtins.filter (
      name:
        (entries.${name} or null)
        == "directory"
        && builtins.pathExists (modulesDir + "/${name}/vm-tests/default.nix")
    )
    stackNames;

  scenariosOf = name: let
    dir = modulesDir + "/${name}/vm-tests";
  in
    lib.mapAttrs' (
      file: _: lib.nameValuePair (lib.removeSuffix ".nix" file) (dir + "/${file}")
    ) (lib.filterAttrs (
      file: type: (type == "regular" || type == "symlink") && lib.hasSuffix ".nix" file
    ) (builtins.readDir dir));

  scenarios = lib.genAttrs stackDirs scenariosOf;

  testName = stack: scenario:
    if scenario == "default"
    then stack
    else "${stack}-${scenario}";

  testEntries =
    lib.concatMap (
      stack:
        lib.mapAttrsToList (
          scenario: path: {
            name = testName stack scenario;
            inherit path;
          }
        )
        scenarios.${stack}
    )
    stackDirs;

  names = map (entry: entry.name) testEntries;
  duplicates = lib.unique (
    lib.filter (name: builtins.length (builtins.filter (n: n == name) names) > 1) names
  );
in {
  inherit scenarios;

  # Flat test name -> module path, e.g. `mealie` and `mealie-no-oidc`.
  testModules =
    if duplicates != []
    then throw "tests/scenarios.nix: duplicate integration test names: ${lib.concatStringsSep ", " duplicates}"
    else builtins.listToAttrs (map (entry: lib.nameValuePair entry.name entry.path) testEntries);
}
