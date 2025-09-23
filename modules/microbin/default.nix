{
  config,
  lib,
  ...
}: let
  name = "microbin";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "Pastebin";
  displayName = "MicroBin";
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

        See <https://microbin.eu/docs/installation-and-configuration/configuration>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/danielszabo99/microbin:2.0.4";
      volumes = [
        "${storage}/data:/app/microbin_data"
      ];
      environment = {
        MICROBIN_PUBLIC_PATH = cfg.containers.${name}.traefik.serviceUrl;
        MICROBIN_ENABLE_BURN_AFTER = true;
        MICROBIN_QR = true;
        MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
        MICROBIN_ENCRYPTION_SERVER_SIDE = true;
        # False enables enternal pastas: https://github.com/szabodanika/microbin/issues/273
        MICROBIN_ETERNAL_PASTA = false;
        MICROBIN_ENABLE_READONLY = true;
        MICROBIN_DISABLE_TELEMETRY = true;
        # Requires MICROBIN_UPLOADER_PASSWORD (e.g. in extraEnv) to take effect
        MICROBIN_READONLY = true;
      };
      extraEnv = cfg.extraEnv;

      port = 8080;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "microbin";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:microbin";
      };
    };
  };
}
