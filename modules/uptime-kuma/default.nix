{
  config,
  lib,
  ...
}: let
  name = "uptime-kuma";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Monitoring";
  description = "Uptime Monitoring";
  displayName = "Uptime Kuma";
in {
  imports = import ../mkAliases.nix config lib name [name];
  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/louislam/uptime-kuma:beta";
      volumeMap = {
        data = "${storage}/data:/app/data";
        socket = "${config.nps.socketLocation}:/var/run/docker.sock:ro";
      };
      environment = {
        UPTIME_KUMA_DB_TYPE = "sqlite";
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
      };

      port = 3001;
      traefik = {
        inherit name;
        subDomain = "uptime";
      };
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:uptime-kuma";
      };
      homepage.settings.widget.type = "uptimekuma";
    };
  };
}
