{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.nps.stacks.glance;
  yaml = pkgs.formats.yaml {};

  dash = import ../dashboard.nix lib;

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
              default = config.dashboard.category;
              description = "Category of the service, `null` hides it on Glance.";
            };
            name = lib.mkOption {
              type = lib.types.str;
              description = "The name of the service as it will displayed on the dashboard.";
              default = config.dashboard.name;
            };
            url = lib.mkOption {
              type = lib.types.str;
              description = "The URL of the service.";
              default =
                if (config.dashboard.url != null)
                then config.dashboard.url
                else "";
            };
          };
        };
        default = {};
        description = ''
          Settings for the service.

          See <https://github.com/glanceapp/glance/blob/main/docs/configuration.md#docker-containers>
        '';
      };

      config.glance = {
        description = lib.mkDefault config.dashboard.description;
        parent = lib.mkDefault config.dashboard.parent;
        icon = lib.mkDefault (dash.toGlance config.dashboard.icon);
        # Glance groups children by the id of their parent, a child must not have one
        id = lib.mkDefault (
          if (config.dashboard.id != null)
          then config.dashboard.id
          else if (config.dashboard.parent == null)
          then name
          else null
        );
      };
    }));
  };
}
