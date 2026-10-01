{
  config,
  lib,
  ...
}: let
  name = "socket-proxy";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  displayName = "Socket Proxy";
  description = "Security Proxy for the Podman Socket";
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    port = lib.mkOption {
      type = lib.types.port;
      internal = true;
      default = 2375;
      description = "Port on which the socket proxy listens.";
    };
    address = lib.mkOption {
      type = lib.types.str;
      default = "tcp://${name}:${toString cfg.port}";
      readOnly = true;
      visible = false;
      description = "The internal address of the Docker Socket Proxy service.";
    };
    sections = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      visible = false;
      default = import ./sections.nix;
      description = ''
        Regex allowlists for the Docker API sections, one per section. Name the
        sections a container needs per HTTP method, and mix in custom regexes,
        e.g. `GET = [sections.containers "some regexp"]`.

        See <https://github.com/wollomatic/socket-proxy/wiki/Docker-API-regex-pattern-index>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/wollomatic/socket-proxy:1.13.1";

      volumeMap.podman-socket = "${config.nps.socketLocation}:/var/run/docker.sock:ro";
      user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";

      environment = {
        SP_PROXYCONTAINERNAME = name;
        SP_LISTENIP = "0.0.0.0";
        SP_PROXYPORT = toString cfg.port;
        SP_WATCHDOGINTERVAL = lib.mkDefault 300;
        SP_STOPONWATCHDOG = lib.mkDefault true;
      };

      port = cfg.port;
      stack = name;
      traefik.name = name;
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:golang";
      };
    };
  };
}
