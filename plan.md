## Feature: Backup Module (Restic + rclone)

### Design

**Global backup config** (`modules/backups/options.nix`) — defaults shared by all services:
- `backupBaseRepository` — directory where per-service restic repos are created: `<base>/<service>`
- `passwordFile` — repository password (can be overridden per service)
- `pruneOpts` — default retention policy
- `timerConfig` — systemd timer for the backup schedule
- `rclone.enable` / `rclone.remotes` — optional cloud mirroring (Backblaze B2, S3, etc.)
- ... other [restic](https://mynixos.com/home-manager/options/services.restic.backups.%3Cname%3E) and [rclone options](https://mynixos.com/home-manager/options/programs.rclone.remotes.%3Cname%3E)

**Per-container extension** — adds `restic` option block to each container (`modules/backups/extension.nix`):
- `restic.enable` — opt in to backing up this container
- `restic.passwordFile` — override the global password
- `restic.pruneOpts` — override default retention
- `restic.paths` — override which directories to back up (default: the service's storage dir + external storage)
- ... other [restic options](https://mynixos.com/home-manager/options/services.restic.backups.%3Cname%3E)

**Service module changes** — each service that needs backups declares:
- Which paths to back up (its `storage` directory, `mediaStorage`, external volumes, etc.)
- `backupPrepareCommand` / `backupCleanupCommand` where needed — e.g. dump the database to a file before backing up, then remove the dump afterward

**How it works** — leverages Home Manager's `services.restic.backups.<name>` 
1. Creates one restic backup entry per container that has `restic.enable = true`
2. Targets `<backupBaseRepository>/<service>` as the restic repo
3. Mounts the backup paths with `paths`, `backupPrepareCommand`, `backupCleanupCommand`
4. If `rclone` is enabled, configures rclone to sync to remotes

### Pseudo Configuration

```nix
nps.stacks = {
  backups = {
    enable = true;
    backupBaseRepository = "/nas/backups/";
    passwordFile = config.sops.secrets.restic_global_password.path;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--keep-yearly 75"
    ];
    timerConfig = {
      OnCalendar = "00:05";
      Persistent = true;
      RandomizedDelaySec = "5h";
    };
    rclone = {
      enable = true;
      remotes.b2 = {
        backupBucket = "my-backup-bucke-123";
        config = {
          type = "b2";
          hard_delete = true;
        };
       secrets.account = config.sops.secrets.b2-acc-id.path;
       };
    };
  };

  baikal = {
    enable = true;
    containers.baikal.restic = {
      enable = true;
      passwordFile = config.sops.secrets.baikal_backup_password.path;
      pruneOpts = [ ];  # never prune this one
    };
  };

  immich = {
    enable = true;
    containers.immich.restic.enable = true;
    # inherits global password and prune opts
  };
};
```
