{
  config,
  lib,
  ...
}: let
  name = "webtop";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  displayName = "Webtop";
  description = "Browser Desktop Environment";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    username = lib.mkOption {
      type = lib.types.str;
      default = "abc";
      description = "Username for HTTP Basic Auth";
    };
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Password for HTTP Basic Auth. If unset, authentication is disabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      # renovate: versioning=regex:^(?<compatibility>.*?)-(?<major>v?\d+)-(?<minor>\d+)-(?<patch>\d+)[\.-]*(?<build>r?\d+)$
      image = "ghcr.io/linuxserver/webtop:arch-xfce-2025-07-12-ls239";
      volumeMap = {
        home = "${storage}/home:/home";
        config = "${storage}/config:/config";
      };
      extraEnv = {
        CUSTOM_USER = cfg.username;
        PASSWORD = lib.mkIf (cfg.passwordFile != null) {fromFile = cfg.passwordFile;};
        PUID = config.nps.defaultUid;
        PGID = config.nps.defaultGid;
        TZ = config.nps.defaultTz;
      };
      extraConfig.Container.ShmSize = "1gb";
      port = 3000;
      traefik.name = name;
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:webtop.png";
      };
    };
  };
}
