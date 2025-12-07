{
  lib,
  config,
  pkgs,
  ...
}: let
  utils = pkgs.callPackage ../utils.nix {inherit config;};
  stackCfg = config.nps.stacks.traefik;
in {
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }: {
          imports = [
            (lib.mkRenamedOptionModule ["port"] ["reverseProxy" "port"])
            (lib.mkRenamedOptionModule ["expose"] ["reverseProxy" "expose"])
            (lib.mkRenamedOptionModule ["traefik" "name"] ["reverseProxy" "serviceName"])
          ];
          options = with lib; {
            traefik = with lib; {
              middleware = mkOption {
                type = types.attrsOf (
                  types.submodule {
                    options = {
                      enable = mkOption {
                        type = types.bool;
                        default = false;
                        description = "Whether the middleware should be applied to the service";
                      };
                      order = lib.mkOption {
                        type = types.int;
                        default = 1000;
                        description = ''
                          Order of the middleware. Middlewares will be called in order by Traefik.
                          Lower number means higher priority.
                        '';
                      };
                    };
                  }
                );
                default = {};
                description = ''
                  A mapping of middleware name to a boolean that indicated if the middleware should be applied to the service.
                '';
              };
            };
          };

          config = let
            traefikCfg = config.traefik;
            reverseProxyCfg = config.reverseProxy;
            port = config.port;

            enableTraefik = stackCfg.enable && reverseProxyCfg.serviceName != null;
            containerPort = utils.reverseProxy.getPort port 1;

            enabledMiddlewares =
              traefikCfg.middleware
              |> lib.filterAttrs (_: v: v.enable)
              |> lib.attrsToList
              |> lib.sortOn (m: m.value.order)
              |> map (m: m.name);
          in {
            # By default, don't expose any service (private middleware), unless public middleware was enabled
            traefik.middleware.private.enable = !reverseProxyCfg.expose;
            traefik.middleware.public.enable = reverseProxyCfg.expose;

            labels = lib.optionalAttrs enableTraefik (
              {
                "traefik.enable" = "true";
                "traefik.http.routers.${name}.rule" = utils.escapeOnDemand ''Host(`${reverseProxyCfg.serviceHost}`)'';
                # "traefik.http.routers.${name}.entrypoints" = "websecure,websecure-internal";
                "traefik.http.routers.${name}.service" = lib.mkDefault name;
              }
              // lib.optionalAttrs (containerPort != null) {
                "traefik.http.services.${name}.loadbalancer.server.port" = containerPort;
              }
              // {
                "traefik.http.routers.${name}.middlewares" = builtins.concatStringsSep "," (
                  map (m: "${m}@file") enabledMiddlewares
                );
              }
            );
          };
        }
      )
    );
  };
  config = let
    validMiddlewares = lib.attrNames stackCfg.dynamicConfig.http.middlewares;
    containersWithMiddleware =
      config.services.podman.containers
      |> lib.attrValues
      |> lib.filter (c: c.reverseProxy.serviceName != null && c.traefik.middleware != {});
  in
    lib.mkIf stackCfg.enable {
      assertions = [
        {
          message = "A Traefik middleware was referenced that is not registered";
          assertion =
            containersWithMiddleware
            |> builtins.all (
              c: c.traefik.middleware |> lib.attrNames |> builtins.all (m: builtins.elem m validMiddlewares)
            );
        }
      ];
    };
}
