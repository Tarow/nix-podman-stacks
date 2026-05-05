lib: let
  inherit (lib) types;
in rec {
  # Options shared by both global defaults and per-container backup configs.
  # Mirrors the shape of services.restic.backups.<name> options.
  resticBackupOptions = {
    passwordFile = lib.mkOption {
      type = types.path;
      description = "File containing the restic repository password.";
      example = lib.literalExpression ''
        config.sops.secrets."restic_password".path
      '';
    };
    pruneOpts = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Retention policy for 'restic forget --prune'.
        See https://restic.readthedocs.io/en/latest/060_forget.html
      '';
      example = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 75"
      ];
    };
    timerConfig = lib.mkOption {
      type = types.nullOr (types.attrsOf (types.oneOf [
        types.str
        types.int
        types.bool
        (types.listOf types.str)
      ]));
      default = {
        OnCalendar = "daily";
        Persistent = true;
      };
      description = ''
        Systemd timer configuration for scheduling backups.
        See systemd.timer(5) for details. If null, no timer is created.
      '';
      example = {
        OnCalendar = "00:05";
        Persistent = true;
        RandomizedDelaySec = "5h";
      };
    };
    initialize = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Initialize the repository if it does not exist.";
    };
    extraBackupArgs = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra arguments passed to restic backup.";
    };
    extraOptions = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra extended options to be passed to restic -o flag.";
    };
    rcloneOptions = lib.mkOption {
      type = types.attrsOf (types.oneOf [types.str types.bool]);
      default = {};
      description = ''
        Options to pass to rclone. Strip leading "--", use hyphens.
      '';
      example = {
        bwlimit = "10M";
        drive-use-trash = true;
      };
    };
    inhibitsSleep = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Prevent the system from sleeping while backing up.";
    };
    checkOpts = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Options for restic check.";
    };
    exclude = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Patterns to exclude when backing up.";
    };
    environmentFile = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "File containing repository access credentials (EnvironmentFile format).";
    };
    dynamicFilesFrom = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Script that produces a list of files to back up.";
    };
  };

  # Rclone remote submodule matching programs.rclone.remotes.<name>.
  rcloneRemoteSubmodule = types.submodule {
    options = {
      type = lib.mkOption {
        type = types.str;
        description = "Rclone remote type (e.g., b2, s3, webdav).";
      };
      config = lib.mkOption {
        type = types.attrsOf (types.nullOr (types.oneOf [
          types.bool
          types.int
          types.float
          types.str
        ]));
        default = {};
        description = "Rclone remote configuration options.";
      };
      secrets = lib.mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          Secret files for the rclone remote. Values are file paths read at runtime.
          Use for passwords, API keys, tokens, etc.
        '';
      };
    };
  };
}
