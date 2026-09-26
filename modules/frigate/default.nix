{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "frigate";
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};

  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  description = "NVR with Real-Time Object Detection";
  displayName = "Frigate";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    mediaPath = lib.mkOption {
      type = lib.types.str;
      default = "${storage}/media";
      defaultText = lib.literalExpression ''"''${config.nps.storageBaseDir}/${name}/media"'';
      description = ''
        Host directory where the Frigate recordings are stored.
      '';
    };
    settings = lib.mkOption {
      type = lib.types.nullOr yaml.type;
      default = null;
      apply = settings:
        if settings != null
        then yaml.generate "config.yml" settings
        else null;
      description = ''
        Settings that will be written to the 'config.yml' file.
        If you want to configure settings through the UI, set this option to null.
        In that case, no managed `config.yml` will be provided.
      '';
    };

    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        Environment variables can be used for substitution in the `config.yml` file.
        See <https://docs.frigate.video/configuration/config#environment-variable-substitution>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/blakeblackshear/frigate:0.18.0";

      volumeMap = {
        config = "${storage}/config:/config";
        media = "${cfg.mediaPath}:/media/frigate";
        settings = lib.mkIf (cfg.settings != null) "${cfg.settings}:/config/config.yml";
      };

      devices = ["/dev/dri:/dev/dri"];

      # https://docs.frigate.video/frigate/installation/#common-docker-compose-storage-configurations
      extraConfig.Container = {
        Tmpfs = lib.mkDefault "/tmp/cache:size=1000000000";
        ShmSize = lib.mkDefault "128m";
      };

      extraEnv = cfg.extraEnv;

      stack = name;
      port = 5000;
      traefik.name = name;

      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:frigate";
      };
    };
  };
}
