{
  config,
  lib,
  ...
}: let
  name = "mealie";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/mealie-recipes/mealie:v3.1.1";
        volumes = ["${storage}/data:/app/data/"];
        environment = {
          ALLOW_SIGNUP = false;
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          BASE_URL = config.services.podman.containers.${name}.traefik.serviceDomain;
          DB_ENGINE = "sqlite";
        };

        port = 9000;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Mealie";
          settings = {
            description = "Recipe Manager";
            icon = "mealie";
            widget.type = "mealie";
          };
        };
      };
    };
  };
}
