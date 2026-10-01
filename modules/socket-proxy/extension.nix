{lib, ...}: let
  httpMethods = ["GET" "HEAD" "POST" "PUT" "DELETE"];

  # First pattern per method is unnumbered, the rest are numbered with a dot
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
          `socket-proxy.allow.get.1`. See `nps.stacks.socket-proxy.sections`.
        '';
        example = lib.literalExpression ''
          {
            GET = [config.nps.stacks.socket-proxy.sections.containers];
            POST = [config.nps.stacks.socket-proxy.sections.build "some custom regex"];
          }
        '';
      };

      config = lib.mkIf (config.socketProxyPermissions != {}) {
        labels = mkLabels config.socketProxyPermissions;
        network = ["socket-proxy"];
        wantsContainer = ["socket-proxy"];
      };
    }));
  };
}
