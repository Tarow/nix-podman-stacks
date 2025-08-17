{
  config,
  lib,
  options,
  ...
}:
let
  name = "vaultwarden";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in
{
  imports = import ../mkAliases.nix config lib name [ name ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = { };
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/dani-garcia/vaultwarden/blob/main/.env.template>
      '';
      example = {
        ADMIN_TOKEN = {
          fromFile = "/run/secrets/vaultwarden_admin_token";
        };
        ADMIN_SESSION_LIFETIME = 30;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/dani-garcia/vaultwarden:1.34.3";
      volumes = [
        "${storage}/data:/data"
      ];
      environment = {
        DOMAIN = cfg.containers.${name}.traefik.serviceDomain;
      };
      extraEnv = cfg.extraEnv;

      port = 80;
      traefik.name = "vw";
      homepage = {
        category = "General";
        name = "Vaultwarden";
        settings = {
          description = "Password Vault";
          icon = "vaultwarden";
        };
      };
    };
  };
}
