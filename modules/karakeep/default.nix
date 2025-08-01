{
  config,
  lib,
  ...
}: let
  name = "karakeep";
  chromeName = "${name}-chrome";
  meilisearchName = "${name}-meilisearch";

  storage = "${config.tarow.podman.storageBaseDir}/${name}";

  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name chromeName meilisearchName];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    envFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to env file containing atleast 'NEXTAUTH_SECRET' and 'MEILI_MASTER_KEY'
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/karakeep-app/karakeep:release";
        volumes = [
          "${storage}/data:/data"
        ];
        environment = {
          DATA_DIR = "/data";
          MEILI_ADDR = "http://${meilisearchName}:7700";
          BROWSER_WEB_URL = "http://${chromeName}:9222";
          NEXTAUTH_URL = cfg.containers.${name}.traefik.serviceDomain;
        };
        environmentFile = [cfg.envFile];

        stack = name;
        port = 3000;
        traefik.name = name;
        homepage = {
          category = "General";
          name = "Karakeep";
          settings = {
            description = "Bookmark Everything";
            icon = "karakeep";
            widget.type = "karakeep";
          };
        };
      };

      ${chromeName} = {
        image = "gcr.io/zenika-hub/alpine-chrome:124";
        exec = lib.concatStringsSep " " [
          "--no-sandbox"
          "--disable-gpu"
          "--disable-dev-shm-usage"
          "--remote-debugging-address=0.0.0.0"
          "--remote-debugging-port=9222"
          "--hide-scrollbars"
        ];

        stack = name;
      };

      ${meilisearchName} = {
        image = "docker.io/getmeili/meilisearch:v1.15.2";
        environment = {
          MEILI_NO_ANALYTICS = "true";
        };
        environmentFile = [cfg.envFile];
        volumes = ["${storage}/meilisearch:/meili_data"];

        stack = name;
      };
    };
  };
}
