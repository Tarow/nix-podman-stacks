{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "glance";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml {};
in {
  imports =
    [
      ./extension.nix
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
    ]
    ++ (import ../mkAliases.nix config lib name [name]);

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = yaml.type;
        options = {
          pages = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
              freeformType = yaml.type;
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = lib.toSentenceCase name;
                  defaultText = lib.literalExpression ''lib.toSentenceCase <pageName>'';
                  description = "The name of the page. Default to the attribute name.";
                };
                columns = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.submodule {
                    freeformType = yaml.type;
                    options = {
                      size = lib.mkOption {
                        type = lib.types.enum ["small" "full"];
                        description = "The size of the column.";
                      };
                      rank = lib.mkOption {
                        type = lib.types.int;
                        default = 1000;
                        description = "The order of the column on the page.";
                      };
                    };
                  });
                  apply = columns: lib.attrValues columns |> lib.sortOn (c: c.rank);
                  description = "The columns to display on the page";
                };
              };
            }));
            apply = lib.attrValues;
          };
        };
      };
      default = {};
      apply = yaml.generate "glance.yml";
      description = ''
        Settings that will be provided as the `glance.yml` configuration file.

        See <https://github.com/glanceapp/glance/blob/main/docs/configuration.md#configuring-glance>
      '';
    };
    userCss = lib.mkOption {
      type = lib.types.lines;
      default = "";
      apply = pkgs.writeText "user.css";
      description = ''
        Custom CSS settings.

        See <https://github.com/glanceapp/glance/blob/main/docs/configuration.md#custom-css-file>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name}.settings = {
      server.assets-path = "/app/assets";
      theme.custom-css-file = "/assets/user.css";
    };

    services.podman.containers.${name} = {
      image = "docker.io/glanceapp/glance:v0.8.4";

      volumes = [
        "${cfg.settings}:/app/config/glance.yml"
        "${cfg.userCss}:/app/assets/user.css"
      ];

      port = 8080;
      traefik = {
        name = name;
        subDomain = "";
      };
    };
  };
}
