{
  config,
  lib,
  ...
}: {
  options.nps.inspection = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    description = ''
      Read-only, Nix-evaluated inspection data and renderings for the final
      Podman container configuration.
    '';
  };

  config.nps.inspection = import ../lib/inspection.nix {inherit config lib;};
}
