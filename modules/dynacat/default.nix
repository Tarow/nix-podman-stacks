{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "dynacat";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  yaml = pkgs.formats.yaml {};

  category = "Network & Administration";
  displayName = "Dynacat";
  description = "Dashboard";
in {
  imports =
    [
      ./extension.nix
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
    ]
    ++ (import ../mkAliases.nix config lib name [name]);

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see <https://dynacat.artur.zone/#authentication/oidc-authentication>
        '';
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };
    secretKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the file containing the secret key used to sign the session cookies.
        Only required when OIDC is enabled.

        Can be generated with
        `podman run --rm panonim/dynacat secret:make`.

        See <https://dynacat.artur.zone/#authentication>
      '';
    };

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
                dynamic-updates = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Whether the page should refresh its widgets automatically.";
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
      apply = yaml.generate "dynacat.yml";
      description = ''
        Settings that will be provided as the `dynacat.yml` configuration file.

        See <https://dynacat.artur.zone/#configuration>
      '';
    };
    userCss = lib.mkOption {
      type = lib.types.lines;
      default = "";
      apply = pkgs.writeText "user.css";
      description = ''
        Custom CSS settings.

        See <https://dynacat.artur.zone/#configuration/custom-css-file>
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://dynacat.artur.zone/#configuration/environment-variables>
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
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/oidc/callback"
        ];
        claims_policy = name;
      };

      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = "group:${cfg.oidc.userGroup}";
          }
        ];
      };

      settings.identity_providers.oidc.claims_policies.${name}.id_token = [
        "email"
        "email_verified"
        "alt_emails"
        "preferred_username"
        "name"
        "groups"
      ];
    };

    nps.stacks.${name}.settings =
      {
        server = {
          assets-path = "/app/assets";
          cache-dir = "/app/data/cache";
          db-path = "/app/data/dynacat.db";
          proxied = lib.mkDefault true;
          trusted-proxies = lib.mkDefault [config.nps.stacks.traefik.network.subnet];
        };
        theme.custom-css-file = "/assets/user.css";
      }
      // lib.optionalAttrs cfg.oidc.enable {
        auth = {
          secret-key = "\${DYNACAT_SECRET_KEY}";
          oidc = {
            issuer-url = config.nps.containers.authelia.traefik.serviceUrl;
            client-id = name;
            client-secret = "\${OIDC_CLIENT_SECRET}";
            redirect-url = "${cfg.containers.${name}.traefik.serviceUrl}/api/oidc/callback";

            allowed-groups = [cfg.oidc.userGroup];
            scopes = ["openid" "profile" "email" "groups"];
            group-claim = "groups";
            username-claim = "preferred_username";
          };
        };
      };

    services.podman.containers.${name} = {
      image = "docker.io/panonim/dynacat:3.0.0";

      volumeMap = {
        settings = "${cfg.settings}:/app/config/dynacat.yml";
        userCss = "${cfg.userCss}:/app/assets/user.css";
        data = "${storage}/data:/app/data";
      };

      extraEnv =
        {
          ENABLE_DYNAMIC_UPDATE = lib.mkDefault true;
          ENABLE_EDITOR = lib.mkDefault false;
        }
        // lib.optionalAttrs cfg.oidc.enable {
          DYNACAT_SECRET_KEY.fromFile = cfg.secretKeyFile;
          OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
        }
        // cfg.extraEnv;

      wantsContainer = lib.optional cfg.oidc.enable "authelia";
      port = 8080;
      traefik.name = name;

      dashboard = {
        inherit category description;
        name = displayName;
        icon = "di:dynacat";
      };
      dynacat.category = null;
    };
  };
}
