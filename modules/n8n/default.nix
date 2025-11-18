{
  config,
  lib,
  ...
}: let
  name = "n8n";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Workflow Automation";
  displayName = "n8n";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.n8n.io/n8nio/n8n:1.121.0";
      # Chown host volume automatically (:U), since n8n will always run as UID/GID 1000
      volumes = ["${storage}/data:/home/node/.n8n:U"];
      environment = {
        DB_TYPE = "sqlite";
        GENERIC_TIMEZONE = config.nps.defaultTz;
        N8N_EDITOR_BASE_URL = cfg.containers.${name}.traefik.serviceUrl;
        N8N_DIAGNOSTICS_ENABLED = false;
      };

      port = 5678;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "n8n";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:n8n";
      };
    };
  };
}
