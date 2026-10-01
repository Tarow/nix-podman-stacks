{lib, ...}: let
  httpMethods = ["GET" "HEAD" "POST" "PUT" "DELETE"];

  # The first pattern uses the plain `socket-proxy.allow.<method>` label,
  # the rest are numbered with a dot.
  mkMethodLabels = method: patterns:
    assert lib.elem method httpMethods || throw "socketProxyPermissions: unknown HTTP method '${method}', expected one of ${lib.concatStringsSep ", " httpMethods}";
      lib.imap1 (
        idx: pattern: {
          name = "socket-proxy.allow.${lib.toLower method}${lib.optionalString (idx > 1) ".${toString (idx - 1)}"}";
          value = pattern;
        }
      )
      patterns;

  mkLabels = permissions:
    lib.listToAttrs (
      lib.concatLists (lib.mapAttrsToList mkMethodLabels permissions)
    );
in {
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
      options.socketProxyPermissions = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = {};
        description = ''
          Regex allowlists for socket-proxy access, one list per HTTP method.
          Generates one label per pattern, e.g. `socket-proxy.allow.get` and
          `socket-proxy.allow.get.1`. Name the API sections the container needs
          and mix in custom regexes, see `nps.stacks.socket-proxy.sections`.

          Example:
          {
            GET = [sections.containers sections.events "some custom regexp"];
            HEAD = [sections.containers];
          }

          See
          - <https://github.com/wollomatic/socket-proxy/wiki/Docker-API-regex-pattern-index>
          - <https://github.com/wollomatic/socket-proxy/wiki/Allowlist-Library>
        '';
      };

      # Only containers that request permissions get labels, so labelling is opt-in.
      config = lib.mkIf (config.socketProxyPermissions != {}) {
        labels = mkLabels config.socketProxyPermissions;
      };
    }));
  };
}
