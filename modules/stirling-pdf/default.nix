{
  config,
  lib,
  ...
}: let
  name = "stirling-pdf";
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/stirlingtools/stirling-pdf:1.3.1";
      environment = {
        DOCKER_ENABLE_SECURITY = false;
        ALLOW_GOOGLE_VISIBILITY = false;
        SYSTEM_ENABLEANALYTICS = false;
      };

      port = 8080;
      traefik.name = "pdf";
      homepage = {
        category = "General";
        name = "Stirling PDF";
        settings = {
          description = "Web-based PDF-Tools";
          icon = "stirling-pdf";
        };
      };
    };
  };
}
