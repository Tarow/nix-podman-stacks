{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "backups";
  cfg = config.nps.stacks.${name};

  allContainers = config.services.podman.containers;
  backupContainers = lib.filterAttrs (_: c: c.backups.enable or false) allContainers;

  splitBackupContainers = lib.filterAttrs (_: c: c.backups.split == true) backupContainers;
  globalBackupContainers = lib.filterAttrs (_: c: c.backups.split == false) backupContainers;

  backupPaths =
    c:
    lib.sort builtins.lessThan (
      lib.unique (
        lib.flatten (
          lib.mapAttrsToList (
            name: c:
            let
              volumes = c.volumeMap or { };
            in
            lib.filter (
              p:
              (lib.hasPrefix "${config.nps.storageBaseDir}" p)
              || (lib.hasPrefix "${config.nps.mediaStorageBaseDir}" p)
            ) (map (v: builtins.head (lib.splitString ":" v)) (lib.attrValues volumes))
          ) c
        )
      )
    );
  resticWrapper = pkgs.writeShellScriptBin "restic-podman-unshare" ''
    exec ${lib.getExe pkgs.podman} unshare ${lib.getExe pkgs.restic} "$@"
  '';

  mkGlobalResticBackup = {
    repository = "${cfg.backupStorageRepository}/global";
    passwordFile = cfg.restic.passwordFile;
    paths = backupPaths globalBackupContainers;
    package = resticWrapper;
    inherit (cfg.restic)
      pruneOpts
      timerConfig
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

  mkSplitResticBackupEntry =
    containerName: container:
    let
      rc = container.backups.restic;
    in
    lib.nameValuePair containerName {
      repository =
        if rc.repository != null then rc.repository else "${cfg.backupStorageRepository}/${containerName}";
      passwordFile = rc.passwordFile;
      pruneOpts = if rc.pruneOpts != null then rc.pruneOpts else cfg.restic.pruneOpts;
      timerConfig = if rc.timerConfig != null then rc.timerConfig else cfg.restic.timerConfig;
      paths = if rc.paths != [ ] then rc.paths else backupPaths { "${containerName}" = container; };
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
in
{
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
  };

  config = lib.mkIf cfg.enable {
    services.restic.enable = lib.mkDefault true;
    services.restic.backups = (lib.mapAttrs' mkSplitResticBackupEntry splitBackupContainers) // {
      global = mkGlobalResticBackup;
    };
    systemd.user.services."restic-backups-global" = {
      Service = {
        PrivateTmp = lib.mkForce false;
      };
    };
  };
}
