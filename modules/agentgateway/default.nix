{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "agentgateway";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};

  category = "Network & Administration";
  displayName = "Agentgateway";
  description = "AI and MCP Gateway";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr yaml.type;
      default = null;
      description = ''
        Settings for Agentgateway, converted to YAML and mounted read-only.
        When null, configuration is managed through the UI and persisted in /config.
        Do not put secrets here, as the generated file is stored in the Nix store.

        See <https://agentgateway.dev/docs/standalone/latest/reference/configuration/schema/>.
      '';
      apply = settings:
        if settings == null
        then null
        else yaml.generate "agentgateway-config.yaml" settings;
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be sourced from a file (e.g. for secrets).

        See <https://agentgateway.dev/docs/standalone/latest/documentation/configuration/static-configuration/>
        and <https://agentgateway.dev/docs/standalone/latest/documentation/llm/api-keys/>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "cr.agentgateway.dev/agentgateway:v1.7.0";
      user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
      volumeMap =
        {
          config = "${storage}/config:/config";
        }
        // lib.optionalAttrs (cfg.settings != null) {
          settings = "${cfg.settings}:/etc/agentgateway/config.yaml:ro";
        };
      exec = lib.mkIf (cfg.settings != null) "-f /etc/agentgateway/config.yaml";
      extraEnv = cfg.extraEnv;
      port = 4000;
      traefik.name = name;
      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:agentgateway";
      };
    };
  };
}
