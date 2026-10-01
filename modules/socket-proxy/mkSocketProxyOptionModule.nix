{
  stack,
  container ? stack,
  targetLocation ? "/var/run/docker.sock",
  subPath ? [],
  permissions ? {},
}: {
  config,
  lib,
  ...
}: let
  stackCfg = config.nps.stacks.${stack};
  cfg = lib.getAttrFromPath (lib.flatten subPath) stackCfg;
  socketProxyCfg = config.nps.stacks.socket-proxy;
  sections = socketProxyCfg.sections;
in {
  options.nps.stacks = lib.setAttrByPath ([stack] ++ (lib.flatten subPath)) {
    useSocketProxy = lib.mkOption {
      type = lib.types.bool;
      default = config.nps.stacks.socket-proxy.enable;
      defaultText = lib.literalExpression ''config.nps.stacks.socket-proxy.enable'';
      description = ''
        Whether to access the Podman socket through the read-only proxy for the ${stack} stack.
        Will be enabled by default if the 'socket-proxy' stack is enabled.
      '';
    };
  };

  config = lib.mkIf stackCfg.enable {
    assertions = let
      optionPath =
        (["nps" "stacks" stack] ++ (lib.flatten subPath))
        |> lib.concatStringsSep ".";
    in [
      {
        assertion = !cfg.useSocketProxy || socketProxyCfg.enable;
        message = "The option '${optionPath}' is set to true, but the 'socket-proxy' stack is not enabled.";
      }
    ];

    services.podman.containers.${container} =
      {
        volumeMap.podman-socket = lib.mkIf (!cfg.useSocketProxy) "${config.nps.socketLocation}:${targetLocation}:ro";
        dependsOn = lib.mkIf (!cfg.useSocketProxy) ["podman.socket"];
      }
      // lib.optionalAttrs cfg.useSocketProxy {
        socketProxyPermissions = lib.mkMerge [
          {
            GET = [sections.version sections.ping];
            HEAD = [sections.ping];
          }
          permissions
        ];
      };
  };
}
