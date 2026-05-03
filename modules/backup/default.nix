{
  config,
  lib,
  ...
}: let
  # The name of your stack/service
  name = "backup";

  # Reference to the stack config (this)
  cfg = config.nps.stacks.${name};

in {
  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

    backupStorageRepository = lib.mkOption {
      type = lib.types.str;
      description = "Backup Storage Repo";
    };
    restic = lib.mkOption {
        
          type = lib.types.str; #I actually want this to be the same type as programs.restic.backups.<name>. Is it lib.types.attrsOf???;
      };

    rclone = lib.mkOption {
      type = lib.types.str; # I actually want this to be the same type as programs.rclone. Is it lib.types.attrsOf???;
      default = {
          enable = false;
        };
      description = '' Rclone config'';
      };
  };

  config = lib.mkIf cfg.enable {

    services.restic = {
        enable = true;
      };

    programs.rclone = lib.mkIf cfg.rclone.enable cfg.rclone;

  };
}
