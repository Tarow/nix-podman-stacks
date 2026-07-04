{
  lib,
  config,
  pkgs,
  ...
}: let
  utils = pkgs.callPackage ../utils.nix {inherit config;};
  stackCfg = config.nps.stacks.traefik;

  ip4Address = config.nps.hostIP4Address;

  getPort = port: index:
    if port == null
    then null
    else if (builtins.isInt port)
    then builtins.toString port
    else builtins.elemAt (builtins.match "([0-9]+):([0-9]+)" port) index;
in {
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }: let
          traefikCfg = config.traefik;
          port = config.port;
        in {
          options = with lib; {
            port = mkOption {
              type = types.nullOr (
                types.oneOf [
                  types.str
                  types.int
                ]
              );
              default = null;
              description = ''
                Main port that Traefik will forward traffic to.
                If Traefik is disabled, it will instead be added to the "ports" section
              '';
            };
            expose = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Whether the service should be exposed (e.g. reachable from external IP addresses).
                When set to `false`, the `private` middleware will be applied by Traefik. The private middleware will only allow requests from
                private CIDR ranges.

                When set to `true`, the `public` middleware will be applied.  The public middleware will allow access from the internet. It will be configured
                with a rate limit, security headers and a geoblock plugin (if enabled). If enabled, Crowdsec will also
                be added to the `public` middleware chain.
              '';
            };
            traefik = with lib; {
              name = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The name of the service as it will be registered in Traefik.
                  Will be used as a default for the subdomain.

                  If not set (null), the service will not be registered in Traefik.
                '';
              };
              subDomain = mkOption {
                type = types.str;
                description = ''
                  The subdomain of the service as it will be registered in Traefik.
                '';
                apply = lib.trim;
                default =
                  if traefikCfg.name != null
                  then traefikCfg.name
                  else "";
                defaultText = "traefikCfg.name";
              };
              serviceAddressInternal = mkOption {
                type = lib.types.str;
                default = let
                  p = getPort port 1;
                in
                  "${name}"
                  + (
                    if (p != null)
                    then ":${p}"
                    else ""
                  );
                defaultText = lib.literalExpression ''"''${containerName}:''${containerCfg.port}"'';
                description = ''
                  The internal main address of the service. Can be used for internal communication
                  without going through Traefik, when inside the same Podman network.
                '';
                readOnly = true;
              };
              serviceHost = mkOption {
                type = lib.types.str;
                description = ''
                  The host name of the service as it will be registered in Traefik.
                '';
                defaultText = lib.literalExpression ''"''${traefikCfg.subDomain}.''${nps.stacks.traefik.domain}"'';
                default = let
                  hostPort = getPort port 0;
                  ipHost =
                    if hostPort == null
                    then "${ip4Address}"
                    else "${ip4Address}:${hostPort}";

                  fullHost =
                    if (stackCfg.enable)
                    then
                      (
                        if (traefikCfg.subDomain == "")
                        then stackCfg.domain
                        else "${traefikCfg.subDomain}.${stackCfg.domain}"
                      )
                    else ipHost;
                in
                  fullHost;
                readOnly = true;
                apply = d: let
                  hostPort = getPort port 0;
                in
                  if stackCfg.enable
                  then d
                  else if hostPort == null
                  then "${ip4Address}"
                  else "${ip4Address}:${hostPort}";
              };
              serviceUrl = mkOption {
                type = lib.types.str;
                description = ''
                  The full URL of the service as it will be registered in Traefik.
                  This will be the serviceHost including the "https://" prefix.
                '';
                default = traefikCfg.serviceHost;
                defaultText = lib.literalExpression ''"https://''${traefikCfg.serviceHost}"'';
                readOnly = true;
                apply = d:
                  if stackCfg.enable
                  then "https://${d}"
                  else "http://${d}";
              };
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
            enableTraefik = stackCfg.enable && traefikCfg.name != null;
            hostPort = getPort port 0;
            containerPort = getPort port 1;
            enabledMiddlewares =
              traefikCfg.middleware
              |> lib.filterAttrs (_: v: v.enable)
              |> lib.attrsToList
              |> lib.sortOn (m: m.value.order)
              |> map (m: m.name);
          in {
            # By default, don't expose any service (private middleware), unless public middleware was enabled
            traefik.middleware.private.enable = !config.expose;
            traefik.middleware.public.enable = config.expose;

            labels = lib.optionalAttrs enableTraefik (
              {
                "traefik.enable" = "true";
                "traefik.http.routers.${name}.rule" = ''Host(`${traefikCfg.serviceHost}`)'';
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
            network = lib.mkIf enableTraefik [stackCfg.network.name];
            ports = lib.optional (!enableTraefik && (port != null)) "${hostPort}:${containerPort}";
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
      |> lib.filter (c: c.traefik.name != null && c.traefik.middleware != {});
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
