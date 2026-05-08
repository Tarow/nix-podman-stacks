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

  prepareCommand =
    c:
    lib.concatStringsSep "\n" (
      lib.sort builtins.lessThan (
        lib.unique (
          lib.mapAttrsToList (
            name: _: "${lib.getExe' pkgs.systemd "systemctl"} --user stop podman-${name}.service"
          ) c
        )
      )
    );

  cleanupCommand =
    c:
    lib.concatStringsSep "\n" (
      lib.sort builtins.lessThan (
        lib.unique (
          lib.mapAttrsToList (
            name: _: "${lib.getExe' pkgs.systemd "systemctl"} --user start podman-${name}.service"
          ) c
        )
      )
    );

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

  mkGlobalResticBackup =
    label: repository:
    lib.nameValuePair "global-${label}" {
      repository = "${repository}/global";
      # repository = "${cfg.backupStorageRepository}/global";
      passwordFile = cfg.restic.passwordFile;
      paths = if cfg.restic.paths != [ ] then cfg.restic.paths else backupPaths globalBackupContainers;

      backupPrepareCommand =
        if cfg.restic.backupPrepareCommand != null then
          cfg.restic.backupPrepareCommand
        else
          prepareCommand globalBackupContainers;
      backupCleanupCommand =
        if cfg.restic.backupCleanupCommand != null then
          cfg.restic.backupCleanupCommand
        else
          cleanupCommand globalBackupContainers;

      package = resticWrapper;
      inherit (cfg.restic)
        pruneOpts
        timerConfig
        initialize
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
    containerName: container: label: repository:
    let
      rc = container.backups.restic;
    in
    lib.nameValuePair "${containerName}-${label}" {
      repository =
        # if rc.repository != null then rc.repository else "${cfg.backupStorageRepository}/${containerName}";
        if rc.repository != null then rc.repository else "${repository}/${containerName}";
      passwordFile = rc.passwordFile;
      pruneOpts = if rc.pruneOpts != null then rc.pruneOpts else cfg.restic.pruneOpts;
      timerConfig = if rc.timerConfig != null then rc.timerConfig else cfg.restic.timerConfig;
      paths = if rc.paths != [ ] then rc.paths else backupPaths { "${containerName}" = container; };
      backupPrepareCommand =
        if rc.backupPrepareCommand != null then
          rc.backupPrepareCommand
        else
          prepareCommand { "${containerName}" = container; };
      backupCleanupCommand =
        if rc.backupCleanupCommand != null then
          rc.backupCleanupCommand
        else
          cleanupCommand { "${containerName}" = container; };
      inherit (rc)
        initialize
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

  mkContainers =
    globalContainers: splitContainers: repositories:
    let
      repos = cfg.repositories;
    in
    builtins.mapAttrs (
      label: repo: lib.mapAttrs' (mkSplitResticBackupEntry splitBackupContainers label repo)
    ) repos
    // builtins.mapAttrs (label: repo: mkGlobalResticBackup label repo) repos;
in
{
  imports = [
    ./extension.nix
  ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

    repositories = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
      description = ''
        Named restic repositories. Each key is a label, each value is a
        restic repository URL or path. These are mapped to restic backup
        entries named after the label.
      '';
      example = lib.literalExpression ''
        {
          global-nas = "/nas/repo";
          global-s3 = "s3:https://s3.example.com/bucket";
        }
      '';
    };

    restic = (import ./options.nix lib).resticBackupOptions // {
      enable = lib.mkEnableOption "restic";
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.enable = lib.mkDefault true;
    # services.restic.backups = (lib.mapAttrs' mkSplitResticBackupEntry splitBackupContainers) // {
    #   global = mkGlobalResticBackup;
    # };
    services.restic.backups =
      mkContainers globalBackupContainers splitBackupContainers
        cfg.repositories;
    systemd.user.services."restic-backups-global" = {
      Service = {
        PrivateTmp = lib.mkForce false;
      };
    };
  };
}
