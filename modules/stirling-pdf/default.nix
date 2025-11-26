{
  config,
  lib,
  ...
}: let
  name = "stirling-pdf";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Web-based PDF-Tools";
  displayName = "Stirling PDF";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/stirlingtools/stirling-pdf:2.0.1";
      environment = {
        DOCKER_ENABLE_SECURITY = false;
        ALLOW_GOOGLE_VISIBILITY = false;
        SYSTEM_ENABLEANALYTICS = false;
      };

      port = 8080;
      traefik.name = "pdf";
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "stirling-pdf";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:stirling-pdf";
      };
    };
  };
}
