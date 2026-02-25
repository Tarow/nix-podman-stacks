{
  config,
  lib,
  ...
}: let
  name = "yopass";
  dbName = "${name}-db";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Share Secrets Securely";
  displayName = "Yopass";
in {
  imports = import ../mkAliases.nix config lib name [name dbName];

  options.nps.stacks.${name}.enable = lib.mkEnableOption name;

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        image = "docker.io/jhaals/yopass:13.0.0";
        exec = "--memcached=${dbName}:11211 --port 8080";

        wantsContainer = [dbName];
        stack = name;
        port = 8080;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "https://repository-images.githubusercontent.com/16027367/5e148d00-d9f9-11e9-8fa7-04b02283d9af";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "https://repository-images.githubusercontent.com/16027367/5e148d00-d9f9-11e9-8fa7-04b02283d9af";
        };
      };

      ${dbName} = {
        image = "docker.io/memcached:1.6.40";
        stack = name;

        glance = {
          parent = name;
          name = "Memcached";
          icon = "sh:memcached";
          inherit category;
        };
      };
    };
  };
}
