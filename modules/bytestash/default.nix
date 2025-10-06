{
  config,
  lib,
  ...
}: let
  name = "bytestash";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  displayName = "ByteStash";
  description = "Code Snippets Organizer";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/jordan-dalby/ByteStash/wiki/FAQ#environment-variables>
      '';
      example = {
        SOME_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        FOO = "bar";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/jordan-dalby/bytestash:1.5.9";

      volumes = ["${storage}/snippets:/data/snippets"];
      environment = {
        BASE_PATH = "";
        TOKEN_EXPIRY = "24h";
        ALLOW_NEW_ACCOUNTS = false;
        DISABLE_ACCOUNTS = false;
        DISABLE_INTERNAL_ACCOUNTS = false;
        ALLOW_PASSWORD_CHANGES = true;
        DEBUG = false;
      };
      extraEnv = cfg.extraEnv;

      port = 5000;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "bytestash";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:bytestash";
      };
    };
  };
}
