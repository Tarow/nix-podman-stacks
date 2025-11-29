{
  config,
  lib,
  ...
}: let
  name = "flaresolverr";
  cfg = config.nps.stacks.${name};

  category = "Media & Downloads";
  displayName = "Flaresolverr";
  description = "Cloudflare Protection Bypass";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = lib.mkIf cfg.enable {
      image = "ghcr.io/flaresolverr/flaresolverr:v3.4.6";
      environment = {
        LOG_LEVEL = "info";
        LOG_HTML = false;
        CAPTCHA_SOLVER = "none";
      };

      homepage = {
        inherit category;
        name = displayName;
        settings = {
          description = description;
          icon = "flaresolverr";
        };
      };
      glance = {
        inherit category;
        description = description;
        name = displayName;
        id = name;
        icon = "di:flaresolverr";
      };
    };
  };
}
