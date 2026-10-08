{
  config,
  lib,
  pkgs,
  ...
}: let
  stackName = "sablier";
  cfg = config.nps.stacks.sablier;

  yaml = pkgs.formats.yaml {};
  recursiveMerge = (import ../lib.nix lib).recursiveMerge;

  mkMiddlewareName = group: "sablier-${group}";
  capitalizeFirst = s:
    lib.toUpper (builtins.substring 0 1 s)
    + builtins.substring 1 (-1) s;

  sablierContainers = lib.filterAttrs (k: c: c.sablier.enable) config.services.podman.containers;
  # All containers of a group share a single middleware, so group them by their group name.
  sablierGroups = lib.groupBy (c: c.sablier.group) (lib.attrValues sablierContainers);
in {
  config = lib.mkIf cfg.enable {
    nps.containers.traefik.wantsContainer = [stackName];
    nps.stacks.traefik = {
      dynamicConfig.http.middlewares =
        lib.mapAttrs' (
          group: containers:
            lib.nameValuePair (mkMiddlewareName group) {
              plugin.sablier = lib.mkMerge [
                {
                  sablierUrl = "http://${cfg.containers.sablier.traefik.serviceAddressInternal}";
                  group = group;
                }
                (recursiveMerge (map (c: c.sablier.middleware) containers))
                (lib.mkIf (cfg.defaultStrategy == "dynamic") {dynamic = lib.mkDefault {displayName = "";};})
                (lib.mkIf (cfg.defaultStrategy == "blocking") {blocking = lib.mkDefault {timeout = "";};})
              ];
            }
        )
        sablierGroups;

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
              default =
                if (config.stack != null)
                then config.stack
                else name;
              defaultText = lib.literalExpression ''containerCfg.stack'';
            };
            middleware = lib.mkOption {
              type = lib.types.attrsOf yaml.type;
              default = {};
              description = ''
                Options for the Traefik Sablier middleware of this container's `group`.

                All containers of a group share one middleware. Their settings are merged:
                attribute sets recursively, lists as a union, other values with the last one winning.

                For details see <https://plugins.traefik.io/plugins/69104ac3b7d4dd76110a1a09/sablier>
              '';
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

        # Everything except `middleware` is forwarded as a label.
        extraConfig."X-Sablier" =
          lib.mapAttrs' (k: v: lib.nameValuePair (capitalizeFirst k) v)
          (lib.removeAttrs config.sablier ["middleware"]);
      };
    }));
  };
}
