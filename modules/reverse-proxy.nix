{
  lib,
  config,
  ...
}: let
  ip4Address = config.nps.hostIP4Address;
  getPort = port: index:
    if port == null
    then null
    else if (builtins.isInt port)
    then builtins.toString port
    else builtins.elemAt (builtins.match "([0-9]+):([0-9]+)" port) index;

  knownReverseProxys = ["traefik" "tsbridge"];
  reverseProxyEnabled = lib.any (name: config.nps.stacks.${name}.enable) knownReverseProxys;
  stackCfg = config.nps.reverseProxy;
in {
  # Internal abstraction. Only one proxy implementation can set these options.
  options.nps.reverseProxy = {
    domain = lib.options.mkOption {
      type = lib.types.str;
      description = "Base domain handled by the reverse proxy";
      visible = false;
    };
    ip4 = lib.options.mkOption {
      type = lib.types.str;
      visible = false;
      description = "IPv4 address of the reverse proxy container in the Podman bridge network";
    };
    network = {
      name = lib.options.mkOption {
        type = lib.types.str;
        description = "Network name for Podman bridge network.";
        visible = false;
      };
      subnet = lib.options.mkOption {
        type = lib.types.str;
        visible = false;
        description = "Subnet of the Podman bridge network";
      };
      gateway = lib.options.mkOption {
        type = lib.types.str;
        visible = false;
        description = "Gateway of the Podman bridge network";
      };
      ipRange = lib.options.mkOption {
        type = lib.types.str;

        visible = false;
        description = "IP-Range of the Podman bridge network";
      };
    };
  };

  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }: let
          proxyCfg = config.reverseProxy;
          port = proxyCfg.port;
        in {
          options = with lib; {
            reverseProxy = with lib; {
              port = mkOption {
                type = types.nullOr (
                  types.oneOf [
                    types.str
                    types.int
                  ]
                );
                default = null;
                description = ''
                  Main port that the reverse proxy will forward traffic to.
                '';
              };
              expose = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Whether the service should be exposed (e.g. reachable from external IP addresses).

                  The implementation depends on the reverse proxy used.

                  For Traefik:
                  When set to `false`, the `private` middleware will be applied by Traefik. The private middleware will only allow requests from
                  private CIDR ranges.

                  When set to `true`, the `public` middleware will be applied.  The public middleware will allow access from the internet. It will be configured
                  with a rate limit, security headers and a geoblock plugin (if enabled). If enabled, Crowdsec will also
                  be added to the `public` middleware chain.
                '';
              };
              serviceName = mkOption {
                type = types.nullOr types.str;
                description = ''
                  The subdomain the service will be reachable as. Defaults to the container name. If set to null, the service will not be registered.
                '';
                default = null;
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
                  without going through the reverse proxy, when inside the same Podman network.
                '';
                readOnly = true;
              };
              serviceHost = mkOption {
                type = lib.types.str;
                description = ''
                  The host name of the service as it will be registered in the reverse proxy.
                '';
                defaultText = lib.literalExpression ''"''${proxyCfg.serviceName}.''${nps.stacks.proxy.domain}"'';
                default = let
                  hostPort = getPort port 0;
                  ipHost =
                    if hostPort == null
                    then "${ip4Address}"
                    else "${ip4Address}:${hostPort}";

                  fullHost =
                    if reverseProxyEnabled
                    then
                      (
                        if (proxyCfg.serviceName == "")
                        then stackCfg.domain
                        else "${proxyCfg.serviceName}.${stackCfg.domain}"
                      )
                    else ipHost;
                in
                  fullHost;
                readOnly = true;
                apply = d: let
                  hostPort = getPort port 0;
                in
                  if reverseProxyEnabled
                  then d
                  else if hostPort == null
                  then "${ip4Address}"
                  else "${ip4Address}:${hostPort}";
              };
              serviceUrl = mkOption {
                type = lib.types.str;
                description = ''
                  The full URL of the service.
                  This will be the serviceHost including the "https://" prefix.
                '';
                default = proxyCfg.serviceHost;
                defaultText = lib.literalExpression ''"https://''${proxyCfg.serviceHost}"'';
                readOnly = true;
                apply = d:
                  if reverseProxyEnabled
                  then "https://${d}"
                  else "http://${d}";
              };
            };
          };
          config = let
            hostPort = getPort port 0;
            containerPort = getPort port 1;
          in {
            network = lib.mkIf reverseProxyEnabled [stackCfg.network.name];
            ports = lib.optional (!reverseProxyEnabled && (port != null)) "${hostPort}:${containerPort}";
          };
        }
      )
    );
  };

  config = lib.mkIf reverseProxyEnabled {
    assertions = [
      {
        assertion = (lib.count (name: config.nps.stacks.${name}.enable) knownReverseProxys) <= 1;
        message = "More than one reverse proxy stack is enabled. Please enable only one of: ${lib.concatStringsSep ", " knownReverseProxys}";
      }
    ];
    services.podman.networks.${stackCfg.network.name} = {
      driver = "bridge";
      subnet = stackCfg.network.subnet;
      gateway = stackCfg.network.gateway;
      extraConfig = {
        Network.IPRange = stackCfg.network.ipRange;
      };
    };
  };
}
