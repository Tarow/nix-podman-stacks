{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nps.stacks.glance;
  yaml = pkgs.formats.yaml {};

  glanceContainers = lib.filterAttrs (k: c: c.glance.category != null) config.services.podman.containers;
  groupByCategory = attrs:
    builtins.foldl' (
      acc: name: let
        value = attrs.${name}.glance;
        category = value.category;
      in
        acc
        // {
          ${category} =
            (acc.${category} or {})
            // {
              ${name} = value;
            };
        }
    ) {} (builtins.attrNames attrs);

  widgets =
    lib.mapAttrsToList (category: containerAttrs: {
      type = "docker-containers";
      title = category;
      category = category;
      sock-path = lib.mkIf (cfg.useSocketProxy) config.nps.stacks.docker-socket-proxy.address;
      containers = containerAttrs;
      running-only = false;
      cache = "30s";
    })
    (groupByCategory glanceContainers);
in {
  config = {
    nps.stacks.glance.settings.pages.home.columns.center = {
      size = lib.mkDefault "full";
      widgets = widgets;
    };
  };

  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options.glance = lib.mkOption {
        type = lib.types.submodule {
          freeformType = yaml.type;
          options = {
            category = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                The category under which the service will be listed on the dashboard.
              '';
            };
            name = lib.mkOption {
              type = lib.types.str;
              description = "The name of the service as it will displayed on the dashboard.";
              default = lib.toSentenceCase name;
              defaultText = lib.literalExpression ''lib.toSentenceCase <containerName>'';
            };
            url = lib.mkOption {
              type = lib.types.str;
              description = "The URL of the service.";
              default = config.traefik.serviceUrl;
            };
          };
        };
        default = {};
        description = ''
          Settings for the service.

          See <https://github.com/glanceapp/glance/blob/main/docs/configuration.md#docker-containers>
        '';
      };
    }));
  };
}
