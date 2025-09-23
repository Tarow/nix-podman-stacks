{
  config,
  lib,
  ...
}: let
  name = "dozzle";
  cfg = config.nps.stacks.${name};
in {
  imports =
    [
      ./extension.nix
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
    ]
    ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable =
    lib.mkEnableOption name
    // {
      description = ''
        Whether to enable Dozzle.
        The module contains an extension that will automatically add all containers to Dozzle groups,
        if they `stack` attribute is set.
      '';
    };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/amir20/dozzle:v8.14.0";
      environment = {
        DOZZLE_REMOTE_HOST = lib.mkIf (cfg.useSocketProxy) config.nps.stacks.docker-socket-proxy.address;
      };

      port = 8080;
      traefik.name = name;
      homepage = {
        category = "Monitoring";
        name = "Dozzle";
        settings = {
          description = "Container Log Viewer";
          icon = "dozzle";
        };
      };
    };
  };
}
