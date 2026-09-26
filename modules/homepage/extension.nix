{
  config,
  lib,
  pkgs,
  ...
}: let
  yaml = pkgs.formats.yaml {};

  dash = import ../dashboard.nix lib;

  homepageContainers = lib.filterAttrs (k: c: c.homepage.category != null) config.services.podman.containers;

  mergedServices =
    builtins.foldl' (
      acc: c: let
        container = c.value;
        category = container.homepage.category;
        serviceName = container.homepage.name;
        serviceSettings = container.homepage.settings;
        existingServices = acc.${category} or {};
      in
        acc
        // {
          "${category}" = existingServices // {"${serviceName}" = serviceSettings;};
        }
    ) {}
    (lib.attrsToList homepageContainers);
in {
  config = {
    nps.stacks.homepage.services = mergedServices;
  };

  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options.homepage = with lib; {
        category = options.mkOption {
          type = types.nullOr types.str;
          default =
            if (config.dashboard.parent != null)
            then null
            else config.dashboard.category;
          defaultText = lib.literalExpression ''config.dashboard.category'';
          description = ''
            Category of the service, `null` hides it on Homepage.
            Containers with a `dashboard.parent` are hidden by default.
          '';
        };
        name = options.mkOption {
          type = types.str;
          default = config.dashboard.name;
          description = "The name of the service as it will appear on the Homepage dashboard.";
        };
        settings = options.mkOption {
          type = yaml.type;
          default = {};
          description = ''
            Settings for the Homepage service.
            This can include widget configuration, rank and so on.

            See <https://gethomepage.dev/configs/services/#services/>
          '';
        };
      };

      config.homepage.settings = {
        href = lib.mkIf (config.dashboard.url != null) (lib.mkDefault config.dashboard.url);
        description = lib.mkDefault config.dashboard.description;
        icon = lib.mkDefault (dash.toHomepage config.dashboard.icon);
        id = lib.mkDefault name;
        server = lib.mkDefault "local";
        container = lib.mkDefault name;
        widget = {
          enable = lib.mkDefault false;
          url = lib.mkDefault "http://${config.traefik.serviceAddressInternal}";
        };
      };
    }));
  };
}
