{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "backup";
  cfg = config.nps.stacks.${name};

  allContainers = config.services.podman.containers;
  backupContainers = lib.filterAttrs (_: c: c.restic.enable or false) allContainers;

  mkBackupEntry = containerName: container: let
    rc = container.restic;
  in
    lib.nameValuePair containerName {
      repository =
        if rc.repository != null
        then rc.repository
        else "${cfg.backupStorageRepository}/${containerName}";
      passwordFile =
        if rc.passwordFile != null
        then rc.passwordFile
        else cfg.restic.passwordFile;
      paths =
        if rc.paths != []
        then rc.paths
        else ["${config.nps.storageBaseDir}/${container.stack or containerName}"];
      pruneOpts =
        if rc.pruneOpts != null
        then rc.pruneOpts
        else cfg.restic.pruneOpts;
      timerConfig =
        if rc.timerConfig != null
        then rc.timerConfig
        else cfg.restic.timerConfig;
      inherit (rc)
        initialize
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
        ;
    };
in {
  imports = [
    ./extension.nix
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

    backupStorageRepository = lib.mkOption {
      type = lib.types.str;
      description = ''
        Base directory or repository prefix for restic backups.
        Each container gets its own sub-repo: <base>/<container-name>
      '';
      example = "/nas/backups/restic";
    };

    restic = (import ./options.nix lib).resticBackupOptions // {
      enable = lib.mkEnableOption "restic";
    };
    

    rclone = {
      enable = lib.mkEnableOption "rclone";
      package = lib.mkPackageOption pkgs "rclone" {};
      remotes = lib.mkOption {
        type = lib.types.attrsOf (import ./options.nix lib).rcloneRemoteSubmodule;
        default = {};
        description = "Rclone remote configurations (e.g., Backblaze B2, S3).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.enable = lib.mkDefault true;
    services.restic.backups =
      builtins.listToAttrs (lib.mapAttrsToList mkBackupEntry backupContainers);

    programs.rclone = lib.mkIf cfg.rclone.enable {
      enable = true;
      package = cfg.rclone.package;
      remotes = lib.mapAttrs (_: remote: {
        type = remote.type;
        config = remote.config;
        secrets = remote.secrets;
      }) cfg.rclone.remotes;
    };
  };
}
