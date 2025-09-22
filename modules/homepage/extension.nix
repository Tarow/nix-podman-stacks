{
  config,
  lib,
  pkgs,
  ...
}: let
  yaml = pkgs.formats.yaml {};

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
          default = null;
          description = ''
            The category under which the service will be listed on the Homepage dashboard.
          '';
        };
        name = options.mkOption {
          type = types.str;
          default = lib.toSentenceCase name;
          defaultText = lib.literalExpression ''lib.toSentenceCase <containerName>'';
          description = ''
            The name of the service as it will appear on the Homepage dashboard.
            Defaults to the container name.
          '';
        };
        settings = options.mkOption {
          type = yaml.type;
          default = {};
          description = ''
            Settings for the Homepage service.
            This can include icon, href, description, widget configuration, etc.

            See <https://gethomepage.dev/configs/services/#services/>
          '';
        };
      };

      config = lib.mkIf (config.homepage.category != null) {
        homepage.settings = {
          href = lib.mkIf (config.traefik.name != null) (lib.mkDefault config.traefik.serviceUrl);
          server = lib.mkDefault "local";
          container = lib.mkDefault name;
          widget = {
            enable = lib.mkDefault false;
            url = lib.mkDefault "http://${name}:${toString config.port}";
          };
        };
      };
    }));
  };
}
