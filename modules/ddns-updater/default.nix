{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "ddns-updater";

  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  displayName = "DDNS-Updater";
  description = "Dynamic DNS Client";

  json = pkgs.formats.json {};
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

        See <https://github.com/qdm12/ddns-updater?tab=readme-ov-file#environment-variables>
      '';
      example = {
        BACKUP_PERIOD = "72h15m";
      };
    };
    settings = lib.mkOption {
      type = lib.types.listOf json.type;

      default = [];
      example = lib.literalExpression ''
        [
          {
            provider = "duckdns";
            domain = "example.duckdns.org";
            token = "{{ file.Read `''${config.sops.secrets."DUCKDNS_TOKEN".path}`}}";
            ip_version = "ipv4";
          }
        ]
      '';
      description = ''
        Configuration settings for ddns-updater.
        Will be provided as the `settings` in the `CONFIG` environment variable.

        The config will be templated using `gomplate`, so you can refer to secrets etc.

        See <https://github.com/qdm12/ddns-updater?tab=readme-ov-file#configuration>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/qdm12/ddns-updater:v2.10.0";
      user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
      volumes = [
        "${storage}/data:/updater/data"
      ];
      extraEnv =
        {
          CONFIG.fromTemplate = builtins.toJSON {settings = cfg.settings;} |> lib.replaceStrings ["\n"] [""];
        }
        // cfg.extraEnv;

      port = 8000;
      traefik.name = name;

      stack = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "ddns-updater";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:ddns-updater";
      };
    };
  };
}
