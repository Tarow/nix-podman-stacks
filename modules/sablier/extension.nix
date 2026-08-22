{
  config,
  lib,
  ...
}: let
  stackName = "sablier";
  cfg = config.nps.stacks.sablier;

  mkMiddlewareName = group: "sablier-${group}";
  capitalizeFirst = s:
    lib.toUpper (builtins.substring 0 1 s)
    + builtins.substring 1 (-1) s;

  sablierContainers = lib.filterAttrs (k: c: c.sablier.enable) config.services.podman.containers;
  sablierGroups =
    sablierContainers
    |> lib.mapAttrsToList (k: c: c.sablier.group)
    |> lib.uniqueStrings;
in {
  config = lib.mkIf cfg.enable {
    nps.containers.traefik.wantsContainer = [stackName];
    nps.stacks.traefik = {
      dynamicConfig.http.middlewares = lib.genAttrs' sablierGroups (
        group:
          lib.nameValuePair (mkMiddlewareName group) {
            plugin.sablier = {
              sablierUrl = "http://${cfg.containers.sablier.traefik.serviceAddressInternal}";
              group = group;
              dynamic = lib.mkIf (cfg.defaultStrategy == "dynamic") (lib.mkDefault {displayName = "";}); # use server default;
              blocking = lib.mkIf (cfg.defaultStrategy == "blocking") (lib.mkDefault {timeout = "";}); # use server default;
            };
          }
      );

      staticConfig.experimental.plugins.sablier = {
        moduleName = "github.com/sablierapp/sablier-traefik-plugin";
        version = "v1.3.0";
      };
    };
  };

  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options.sablier = lib.mkOption {
        type = lib.types.submodule {
          freeformType = lib.types.attrsOf lib.types.str;
          options = {
            enable = lib.mkEnableOption "Sablier integration";
            group = lib.mkOption {
              type = lib.types.str;
              description = ''
                Group the container belongs to.

                For details see <https://sablierapp.dev/concepts/groups/>
              '';
              default = config.stack;
              defaultText = lib.literalExpression ''containerCfg.stack'';
            };
          };
        };
        default = {};
        description = ''
          Sablier labels for the container. Must use the systemd style label names.
          The labels will be provided in the [X-Sablier] section of the unit file for the container.
        '';
      };
      config = lib.mkIf (cfg.enable && config.sablier.enable) {
        traefik.middleware.${mkMiddlewareName config.sablier.group}.enable = true;
        extraConfig."X-Sablier" = lib.mapAttrs' (k: v: lib.nameValuePair (capitalizeFirst k) v) config.sablier;
      };
    }));
  };
}
