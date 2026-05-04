{
  config,
  lib,
  pkgs,
  ...
}: let
  backupOpts = import ./options.nix lib;
in {
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }: let
          resticCfg = config.restic;
        in {
          options = with lib; {
            restic = {
              enable = mkEnableOption ''
                backup for this container. Generates a restic-backups-<name> systemd service.
              '';

              paths = mkOption {
                type = types.listOf types.str;
                default = [];
                description = ''
                  Directories to back up. Set this to the service's storage dir,
                  media dir, and any external volumes.
                '';
                example = literalExpression ''
                  ["''${config.nps.storageBaseDir}/myservice"]
                '';
              };

              repository = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Restic repository URL. Defaults to <backupBaseRepository>/<container-name>.
                '';
              };

              passwordFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  Override the global password file. Set to null to inherit the global default.
                '';
              };

              pruneOpts = mkOption {
                type = types.nullOr (types.listOf types.str);
                default = null;
                description = ''
                  Override global prune options. Set to [] to never prune this backup.
                  Set to null to inherit the global default.
                '';
              };

              timerConfig = mkOption {
                type = types.nullOr (types.attrsOf (types.oneOf [
                  types.str
                  types.int
                  types.bool
                  (types.listOf types.str)
                ]));
                default = null;
                description = ''
                  Override global timer configuration. Set to null to inherit global default.
                '';
              };

              backupPrepareCommand = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Shell command to run before backup. Useful for dumping a database
                  to a file before backing it up.
                '';
                example = ''
                  pg_dump -U myapp myappdb > /tmp/myapp-db-dump.sql
                '';
              };

              backupCleanupCommand = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Shell command to run after backup completes. Useful for removing
                  temporary files created by backupPrepareCommand.
                '';
                example = ''
                  rm /tmp/myapp-db-dump.sql
                '';
              };

              # Pass-through options inherited from the global defaults
              inherit (backupOpts.resticBackupOptions)
                extraBackupArgs
                extraOptions
                rcloneOptions
                inhibitsSleep
                checkOpts
                exclude
                environmentFile
                dynamicFilesFrom
                initialize;
            };
          };
        }
      )
    );
  };
}
