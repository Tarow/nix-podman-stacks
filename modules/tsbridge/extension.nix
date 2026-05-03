{
  lib,
  config,
  ...
}: let
  stackCfg = config.nps.stacks.tsbridge;
in {
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }: let
          tsbridgeCfg = config.tsbridge;
        in {
          options = with lib; {
            tsbridge = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether this service should be exposed via tsbridge.
                  When enabled, the service will be accessible on your Tailnet.
                '';
              };

              port = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = ''
                  The port that tsbridge should proxy to.
                  Either port or backendAddr must be specified.
                '';
              };

              backendAddr = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The full backend address (host:port) that tsbridge should proxy to.
                  Either port or backendAddr must be specified.
                  Use this when you need to specify a different host than the container name.
                '';
              };

              serviceName = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Optional custom name for the service on the Tailnet.
                  If not specified, the container name will be used.
                '';
              };

              whoisEnabled = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to enable whois information for this service.
                  When enabled, clients can see which user is accessing the service.
                '';
              };

              funnelEnabled = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to expose this service to the internet via Tailscale Funnel.
                  When enabled, the service will be publicly accessible, not just on your Tailnet.
                  Requires Funnel to be enabled in your Tailscale settings.
                '';
              };

              ephemeral = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to make this service's node ephemeral.
                  Ephemeral nodes don't persist state and are automatically removed when they disconnect.
                '';
              };

              tags = mkOption {
                type = types.listOf types.str;
                default = [];
                description = ''
                  Tailscale tags to apply to this service.
                  These are in addition to any default tags configured on the tsbridge container.
                  Format: tag:service
                '';
                example = ["tag:prod" "tag:api"];
              };

              listenAddr = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Custom listen address for this service.
                  Format: :port
                  If not specified, a random port will be assigned.
                '';
                example = ":8080";
              };

              flushInterval = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Interval for flushing responses (useful for streaming).
                  Format: duration string (e.g., "30s", "1m")
                  Set to "-1ms" to disable buffering.
                '';
                example = "-1ms";
              };

              headers = mkOption {
                type = types.attrsOf types.str;
                default = {};
                description = ''
                  Additional HTTP headers to add to proxied requests.
                '';
                example = {
                  "X-Custom-Header" = "value";
                };
              };

              insecureSkipVerify = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to skip TLS certificate verification for HTTPS backends.
                  Only use this for trusted internal services with self-signed certificates.
                '';
              };

              serviceHost = mkOption {
                type = types.str;
                description = ''
                  The full hostname of the service on the Tailnet.
                  Format: serviceName.tailnet-domain
                '';
                default = 
                  let
                    serviceName = if tsbridgeCfg.serviceName != null
                                  then tsbridgeCfg.serviceName
                                  else name;
                  in "${serviceName}.${stackCfg.tailnetDomain}";
                defaultText = lib.literalExpression ''
                  "''${tsbridgeCfg.serviceName or containerName}.''${stackCfg.tailnetDomain}"
                '';
                readOnly = true;
              };

              serviceUrl = mkOption {
                type = types.str;
                description = ''
                  The full HTTPS URL of the service on the Tailnet.
                '';
                default = "https://${tsbridgeCfg.serviceHost}";
                defaultText = lib.literalExpression ''"https://''${tsbridgeCfg.serviceHost}"'';
                readOnly = true;
              };
            };
          };

          config = let
            enableTsbridge = stackCfg.enable && tsbridgeCfg.enable;
            hasPort = tsbridgeCfg.port != null;
            hasBackendAddr = tsbridgeCfg.backendAddr != null;
          in {
            # Assertions are now at the root module level (see below)
            labels = lib.optionalAttrs enableTsbridge (
              {
                "tsbridge.enabled" = "true";
              }
              // (lib.optionalAttrs hasPort {
                "tsbridge.service.port" = toString tsbridgeCfg.port;
              })
              // (lib.optionalAttrs hasBackendAddr {
                "tsbridge.service.backend_addr" = tsbridgeCfg.backendAddr;
              })
              // (lib.optionalAttrs (tsbridgeCfg.serviceName != null) {
                "tsbridge.service.name" = tsbridgeCfg.serviceName;
              })
              // (lib.optionalAttrs tsbridgeCfg.whoisEnabled {
                "tsbridge.service.whois_enabled" = "true";
              })
              // (lib.optionalAttrs tsbridgeCfg.funnelEnabled {
                "tsbridge.service.funnel_enabled" = "true";
              })
              // (lib.optionalAttrs tsbridgeCfg.ephemeral {
                "tsbridge.service.ephemeral" = "true";
              })
              // (lib.optionalAttrs (tsbridgeCfg.tags != []) {
                "tsbridge.service.tags" = lib.concatStringsSep "," tsbridgeCfg.tags;
              })
              // (lib.optionalAttrs (tsbridgeCfg.listenAddr != null) {
                "tsbridge.service.listen_addr" = tsbridgeCfg.listenAddr;
              })
              // (lib.optionalAttrs (tsbridgeCfg.flushInterval != null) {
                "tsbridge.service.flush_interval" = tsbridgeCfg.flushInterval;
              })
              // (lib.optionalAttrs (tsbridgeCfg.insecureSkipVerify) {
                "tsbridge.service.insecure_skip_verify" = "true";
              })
              // (lib.foldl' (acc: name: acc // {
                "tsbridge.service.upstream_headers.${name}" = tsbridgeCfg.headers.${name};
              }) {} (lib.attrNames tsbridgeCfg.headers))
            );

            # Services using tsbridge must be on the same network
            network = lib.mkIf enableTsbridge [stackCfg.network.name];
          };
        }
      )
    );
  };

  # Root-level assertions for tsbridge configuration
  config.assertions =
    lib.mapAttrsToList (
      name: containerCfg: let
        tsbridgeCfg = containerCfg.tsbridge;
        enableTsbridge = stackCfg.enable && tsbridgeCfg.enable;
        hasPort = tsbridgeCfg.port != null;
        hasBackendAddr = tsbridgeCfg.backendAddr != null;
      in [
        {
          assertion = !enableTsbridge || (hasPort || hasBackendAddr);
          message = "Container '${name}': tsbridge.enable is true but neither tsbridge.port nor tsbridge.backendAddr is specified.";
        }
        {
          assertion = !enableTsbridge || !(hasPort && hasBackendAddr);
          message = "Container '${name}': Both tsbridge.port and tsbridge.backendAddr are specified. Only one should be set.";
        }
      ]
    ) config.services.podman.containers
    |> lib.flatten;
}
