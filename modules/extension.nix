{
  pkgs,
  lib,
  config,
  ...
}: let
  globalConf = config;
  mkSocketName = {
    name,
    port,
    prefix ? "podman-",
    suffix ? ".socket",
  }: "${prefix}${name}-${toString port |> lib.replaceStrings ["." ":"] ["_" "-"]}${suffix}";
in {
  # Extend the podman options in order to custom build custom abstraction
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options = with lib; {
        dependsOn = mkOption {
          type = types.listOf types.str;
          default = [];
        };

        dependsOnContainer = mkOption {
          type = types.listOf types.str;
          default = [];
          apply = map (d: "podman-${d}.service");
        };

        socketActivation = mkOption {
          type = types.listOf (types.submodule {
            options = {
              port = mkOption {
                type = types.oneOf [types.str types.port];
              };
              fileDescriptorName = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          });
          default = [];
        };

        stack = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Stack that a container is part of";
        };
      };

      config = {
        autoUpdate = lib.mkDefault "registry";

        network = lib.mkIf (config.stack != null) [config.stack];
        dependsOn =
          (map (sa:
            mkSocketName {
              inherit name;
              port = sa.port;
            })
          config.socketActivation)
          ++ lib.optional (builtins.any (lib.hasPrefix "${globalConf.tarow.podman.socketLocation}:") config.volumes) "podman.socket";

        environment.TZ = lib.mkDefault globalConf.tarow.podman.defaultTz;

        extraConfig = {
          Unit.Requires = config.dependsOn ++ config.dependsOnContainer;
          Unit.After = config.dependsOn ++ config.dependsOnContainer;

          # Automatically create host directories for volumes if they don't exist
          Service.ExecStartPre = let
            volumes = map (v: lib.head (lib.splitString ":" v)) (config.volumes or []);
            volumeDirs = lib.filter (v: lib.hasInfix "/" v && !lib.hasPrefix "/run" v) volumes;
          in "${lib.getExe (pkgs.writeShellApplication {
            name = "setupVolumes";
            runtimeInputs = [pkgs.coreutils];
            text = (map (v: "[ -e ${v} ] || mkdir -p ${v}") volumeDirs) |> lib.concatStringsSep "\n";
          })}";
        };
      };
    }));
  };

  config = {
    # For every stack, define a default network.
    services.podman.networks = let
      stacks =
        config.services.podman.containers
        |> builtins.attrValues
        |> builtins.filter (c: c.stack != null)
        |> builtins.map (c: c.stack);
    in
      lib.genAttrs stacks (s: lib.mkDefault {driver = "bridge";});

    # Create sockets for socketActivated containers
    systemd.user.sockets = let
      containers = lib.filterAttrs (n: v: v.socketActivation != []) config.services.podman.containers;
      mkSockets = name: container:
        map (sa:
          lib.nameValuePair (mkSocketName {
            inherit name;
            port = sa.port;
            suffix = "";
          }) {
            Socket.ListenStream = "${toString sa.port}";
            Socket.ListenDatagram = "${toString sa.port}";
            Socket.Service = "podman-${name}.service";
            Socket.FileDescriptorName = lib.mkIf (sa.fileDescriptorName != null) sa.fileDescriptorName;
            Install.WantedBy = ["sockets.target"];
          })
        container.socketActivation;
      sockets = (lib.mapAttrsToList mkSockets containers) |> lib.flatten |> lib.listToAttrs;
    in
      sockets;
  };
}
