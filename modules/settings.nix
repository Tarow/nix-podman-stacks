{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.nps;

  anyStackEnabled =
    config.nps.stacks
    |> lib.attrValues
    |> lib.any (s: s.enable or false);

  keepHostIdContainers = [
    {
      match = "docker.io/(postgres|mysql|mariadb|redis):.*";
      userNS = "keep-id:uid=999,gid=999";
    }
    {
      match = "docker.io/kimai/kimai2:.*";
      userNS = "keep-id:uid=33,gid=33";
    }
    {
      match = "ghcr.io/danielbrendel/hortusfox-web:.*";
      user = "0:0";
      userNS = "keep-id:uid=33,gid=33";
    }
    {
      match = "docker.io/ckulka/baikal:.*";
      user = "0:0";
      userNS = "keep-id:uid=101,gid=101";
    }
    {
      enable = false; # Causes podman to freeze completely. Long running chown process? https://github.com/containers/podman/issues/16830
      match = "docker.n8n.io/n8nio/n8n:.*";
      userNS = "keep-id:uid=1000,gid=1000";
    }
  ];
in {
  imports = [
    ./extension.nix
    {
      # Add user-ns mapping to all "whitelisted" containers
      options.services.podman.containers = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            {config, ...}: let
              settings = lib.findFirst (c: (c.enable or true) && (lib.match c.match config.image != null)) null keepHostIdContainers;
            in
              lib.mkIf (cfg.preferHostIds && settings != null) {
                user = lib.mkIf ((settings.user or null) != null) settings.user;
                extraConfig.Container.UserNS = lib.mkIf ((settings.userNS or null) != null) settings.userNS;
              }
          )
        );
      };
    }
  ];

  options.nps = {
    package = lib.mkPackageOption pkgs "podman" {};
    enableSocket = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable the Podman socket for user services.
        Note that the socket is required for the services like Traefik or Homepage to run successfully, since they access the Podman API.

        If this is disabled and you use these services, you will need to manually enable the socket.
      '';
    };
    socketLocation = lib.mkOption {
      type = lib.types.path;
      default = "/run/user/${toString cfg.hostUid}/podman/podman.sock";
      defaultText = lib.literalExpression ''"/run/user/''${toString config.nps.hostUid}/podman/podman.sock"'';
      readOnly = true;
      description = ''
        The location of the Podman socket for user services.
        Will be passed to containers that communicate with the Podman API, such as Traefik, Homepage or Beszel.
      '';
    };
    hostUid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = ''
        UID of the host user running the containers.
        Will be used to infer the Podman socket location (XDG_RUNTIME_DIR).
      '';
    };
    defaultUid = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        > [!WARNING]
        > Do not change this value unless you know what you are doing!
        > You might run into permisssion issues if volumes cannot be accessed by the mapped subuid.

        UID of the user that will be used by default for containers if they allow UID configuration.
        When running rootless containers, UID 0 gets mapped to the host users UID.
      '';
    };
    defaultGid = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        > [!WARNING]
        > Do not change this value unless you know what you are doing!
        > You might run into permisssion issues if volumes cannot be accessed by the mapped subgid.

        GID of the user that will be used by default for containers if they allow GID configuration.
        When running rootless containers, GID 0 gets mapped to the host users GID.
      '';
    };
    defaultTz = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Etc/UTC";
      description = ''
        Default timezone for containers.
        Will be passed to all containers as `TZ` environment variable.
      '';
    };
    storageBaseDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/stacks";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/stacks"'';
      description = ''
        Base directory for Podman storage.
        This is where each stack will create its bind mounts for persistent data.
        For example, setting this to `/home/foo/stacks` would result in Adguard creating its bind mount at `/home/foo/stacks/adguard`.
      '';
    };
    externalStorageBaseDir = lib.mkOption {
      type = lib.types.path;
      description = ''
        Base location that will be used for larger data such as downloads or media files.
        Could be an external disk.
      '';
    };
    mediaStorageBaseDir = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.externalStorageBaseDir}/media";
      defaultText = lib.literalExpression ''"''${config.nps.externalStorageBaseDir}/media"'';
      description = ''
        Base location for larger media files.
        This is where containers like Jellyfin or Immich will store their media files.
      '';
    };
    hostIP4Address = lib.mkOption {
      type = lib.types.str;
      description = ''
        The IPv4 address which will be used in case explicit bindings are required.
      '';
    };
    preferHostIds = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to prefer host user mapping over subuid/subgids.

        Some containers will always run with a certain UID/GID. Popular examples are Postgres, MySQL and MariaDB (999/999).
        When running those containers with rootless Podman, files created within volumes will be owned by subuids/subgids.
        While this is generally not a problem and might even be desired, it can cause issues for example in combination with NFS shares.

        Enabling this option will cause the container user (e.g. 999) to be mapped to the host user. Files created by the container will then be
        owned be the host user running the containers. This achieved by using `userns=keep-id:uid=<container-user>,gid=<container-group>`.

        For more infos, see <https://docs.podman.io/en/stable/markdown/podman-run.1.html#userns-mode>

        Be aware that this option is not supported for all containers that run as a fixed user.
        As the userns setting will also change the init user a container is started as, it would break containers that require being started as root
        to chown files etc. before dropping permissions.
      '';
    };
  };

  config = lib.mkIf anyStackEnabled {
    services.podman = {
      enable = true;
      package = cfg.package;

      settings.containers.network.dns_bind_port = 1153;
    };

    systemd.user.sockets.podman = lib.mkIf cfg.enableSocket {
      Install.WantedBy = ["sockets.target"];
      Socket = {
        SocketMode = "0660";
        ListenStream = cfg.socketLocation;
      };
    };
    systemd.user.services.podman = lib.mkIf cfg.enableSocket {
      Install.WantedBy = ["default.target"];
      Service = {
        Delegate = true;
        Type = "exec";
        KillMode = "process";
        Environment = ["LOGGING=--log-level=info"];
        ExecStart = "${lib.getExe cfg.package} $LOGGING system service";
      };
    };
  };
}
