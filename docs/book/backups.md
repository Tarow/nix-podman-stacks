# Backups

There is no backup stack or extension, mainly because requirements around backups are highly individual and because Home Manger already has good backup options.

To backup your Podman stacks data, this page contains a few examples, using Home Managers existing [`services.restic`](https://search.nixos.org/options?channel=unstable&query=services.restic&source=home_manager) options.

> [!NOTE]
> Because the files of some stacks will be owned by subuids/subgids, you may have to to provide a custom restic wrapper package that invokes restic using `podman unshare` to avoid permission issues:
>
> ```nix
> services.restic.backups.<name>.package = pkgs.writeShellScriptBin "restic-podman-unshare" ''
>  exec ${lib.getExe pkgs.podman} unshare ${lib.getExe pkgs.restic} "$@"
> '';
>
> ```

## All Stacks & Single Repository

```nix
{config, lib, pkgs, ...}: {
  services.restic = {
    enable = true;
    backups.somebackup = {
      initialize = true;
      repository = "${config.home.homeDirectory}/restic/nps";
      passwordFile = config.sops.secrets."restic/nps_password".path;

      backupPrepareCommand = "${pkgs.systemd}/bin/systemctl --user stop 'podman-*'";
      backupCleanupCommand = "${pkgs.systemd}/bin/systemctl --user start 'podman-*' --all";

      paths = [config.nps.storageBaseDir config.nps.mediaStorageBaseDir];
    };
  };
}
```

## Individual Stacks & Single Repository

```nix
{config, lib, pkgs, ...}: {
  services.restic = let
    stacks = ["lldap" "paperless" "karakeep"];
    systemdServices = lib.concatMapStringsSep " " (s: "'podman-${s}*'") stacks;
  in {
    enable = true;
    backups.somebackup = {
      initialize = true;
      repository = "${config.home.homeDirectory}/restic/somebackup";
      passwordFile = config.sops.secrets."restic/nps_password".path;

      backupPrepareCommand = "${pkgs.systemd}/bin/systemctl --user stop ${systemdServices}";
      backupCleanupCommand = "${pkgs.systemd}/bin/systemctl --user start ${systemdServices} --all";

      paths = map (name: "${config.nps.storageBaseDir}/${name}") stacks;
    };
  };
}
```

## Individual Stacks & Separate Repositories

```nix
{config, lib, pkgs, ...}: {
  services.restic = let
    stacks = ["lldap" "paperless" "karakeep"];
  in {
    enable = true;
    backups = lib.genAttrs stacks (name: {
      initialize = true;
      repository = "${config.home.homeDirectory}/restic/backups/${name}";
      passwordFile = config.sops.secrets."restic/nps_password".path;

      backupPrepareCommand = "${pkgs.systemd}/bin/systemctl --user stop 'podman-${name}*'";
      backupCleanupCommand = "${pkgs.systemd}/bin/systemctl --user start 'podman-${name}*' --all";

      paths = ["${config.nps.storageBaseDir}/${name}"];
    });
  };
}
```
