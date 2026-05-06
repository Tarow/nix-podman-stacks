{
  config,
  lib,
  pkgs,
  ...
}:
let
  backupOpts = import ./options.nix lib;
in
{
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }:
        let
          backupsCfg = config.backups;
        in
        {
          options = with lib; {
            backups = {
              enable = mkEnableOption ''
                enable backups for this container.
              '';

              split = mkOption {
                type = types.bool;
                default = false;
                description = "Split backup across multiple repos.";
              };

              restic = {
                enable = mkEnableOption ''
                  enable split backup for this container. Generates a restic-backups-<name> systemd service.
                '';

                # Pass-through options inherited from the global defaults
                inherit (backupOpts.resticBackupOptions)
                  paths
                  repository
                  passwordFile
                  pruneOpts
                  timerConfig
                  backupPrepareCommand
                  backupCleanupCommand
                  extraBackupArgs
                  extraOptions
                  rcloneOptions
                  inhibitsSleep
                  checkOpts
                  exclude
                  environmentFile
                  dynamicFilesFrom
                  initialize
                  ;
              };
            };
          };
        }
      )
    );
  };
}
