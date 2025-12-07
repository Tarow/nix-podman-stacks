{
  lib,
  config,
  pkgs,
  ...
}: let
  stackCfg = config.nps.stacks.tsbridge;
  utils = pkgs.callPackage ../utils.nix {inherit config;};
in {
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }: {
          options = with lib; {
            tsbridge = {
              backendAddr = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The full backend address (host:port) that tsbridge should proxy to.
                  Either port or backendAddr must be specified.
                  Use this when you need to specify a different host than the container name.
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

              enableFunnel = mkOption {
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
            };
          };

          config = let
            tsbridgeCfg = config.tsbridge;
            reverseProxyCfg = config.reverseProxy;
            port = config.reverseProxy.port;

            enableTsbridge = stackCfg.enable && reverseProxyCfg.serviceName != null;
            containerPort = utils.reverseProxy.getPort port 1;
          in
            lib.mkIf enableTsbridge {
              tsbridge.enableFunnel = config.reverseProxy.expose;
              labels =
                {
                  "tsbridge.enabled" = "true";
                  "tsbridge.service.name" =
                    if reverseProxyCfg.serviceName != ""
                    then reverseProxyCfg.serviceName
                    else ''\"\"'';
                  "tsbridge.service.port" = containerPort;
                }
                // (lib.optionalAttrs tsbridgeCfg.whoisEnabled {
                  "tsbridge.service.whois_enabled" = "true";
                })
                // (lib.optionalAttrs tsbridgeCfg.enableFunnel {
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
                // (lib.foldl' (acc: name:
                  acc
                  // {
                    "tsbridge.service.upstream_headers.${name}" = tsbridgeCfg.headers.${name};
                  }) {} (lib.attrNames tsbridgeCfg.headers));
            };
        }
      )
    );
  };
}
