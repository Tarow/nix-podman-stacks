{
  stack,
  container ? stack,
  targetLocation ? "/var/run/docker.sock",
  subPath ? [],
}: {
  config,
  lib,
  ...
}: let
  stackCfg = config.nps.stacks.${stack};
  cfg = lib.getAttrFromPath (lib.flatten subPath) stackCfg;
  socketProxyCfg = config.nps.stacks.docker-socket-proxy;
in {
  options.nps.stacks = lib.setAttrByPath ([stack] ++ (lib.flatten subPath)) {
    useSocketProxy = lib.mkOption {
      type = lib.types.bool;
      default = config.nps.stacks.docker-socket-proxy.enable;
      defaultText = lib.literalExpression ''config.nps.stacks.docker-socket-proxy.enable'';
      description = ''
        Whether to access the Podman socket through the read-only proxy for the ${stack} stack.
        Will be enabled by default if the 'docker-socket-proxy' stack is enabled.
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
        message = "The option '${optionPath}' is set to true, but the 'docker-socket-proxy' stack is not enabled.";
      }
    ];

    services.podman.containers.${container} = {
      # Socket Proxy option exists, but it not used.
      # Mount the socket directly then.
      volumes = lib.mkIf (!cfg.useSocketProxy) [
        "${config.nps.socketLocation}:${targetLocation}:ro"
      ];

      # If socket-proxy is used, add the container to its bridge network so the proxy can be reached
      network = lib.optional cfg.useSocketProxy "docker-socket-proxy";

      # Socket Proxy option is set, add systemd dependency to socket-proxy service
      wantsContainer = lib.mkIf cfg.useSocketProxy ["docker-socket-proxy"];
      dependsOn = lib.mkIf (!cfg.useSocketProxy) ["podman.socket"];
    };
  };
}
