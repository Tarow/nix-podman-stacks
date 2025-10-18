{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "filebrowser-quantum";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";
  yaml = pkgs.formats.yaml {};

  category = "General";
  displayName = "Filebrowser Quantum";
  description = "Web-based File Manager";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    mounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.path;
              description = "Path of the source in the container";
              example = "/mnt/folder";
            };
            name = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Optional name of the source, otherwise the source gets named the folder name";
              default = null;
              example = "folder";
            };
            config = lib.mkOption {
              type = lib.types.submodule {
                freeformType = yaml.type;
              };
              default = {};
              description = ''
                Additional configuration options for the source.

                See <https://github.com/gtsteffaniak/filebrowser/wiki/Configuration-And-Examples#example-advanced-source-config>
              '';
            };
          };
        }
      );
      default = {};
      description = ''
        Mount configuration for the file browser.
        Format: `{ 'hostPath' = container-source-config }`

        The mounts will be added to the settings `source` section and a volume mount will be added for each configured source.

        See <https://github.com/gtsteffaniak/filebrowser/wiki/Configuration-And-Examples#example-advanced-source-config>
      '';
      example = {
        "/mnt/ext/data" = {
          path = "/data";
          name = "ext-data";
        };
        "/home/foo/media" = {
          path = "/media";
          config = {
            disableIndexing = false;
            exclude = {
              fileEndsWith = [".zip" ".txt"];
            };
          };
        };
      };
    };
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Settings that will be added to the `config.yml`.
        To configure sources, you should prefer using the `mounts` option, as the corresponding volume mappings will be
        configured automatically.

        See <https://github.com/gtsteffaniak/filebrowser/wiki/Configuration-And-Examples#configuring-your-application>
      '';
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable OIDC login with Authelia. This will register an OIDC client in Authelia
          and setup the necessary configuration.

          For details, see:

          - <https://www.authelia.com/integration/openid-connect/clients/filebrowser-quantum/>
          - <https://github.com/gtsteffaniak/filebrowser/wiki/Configuration-And-Examples#openid-connect-configuration-oidc>
        '';
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          The file containing the client secret for the OIDC client that will be registered in Authelia.
        '';
      };
      clientSecretHash = lib.mkOption {
        type = lib.types.str;
        description = ''
          The hashed client_secret. Will be set in the Authelia client config.
          For examples on how to generate a client secret, see

          <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
        '';
      };
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = "Users of this group will be assigned admin rights";
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users of this group will be able to log in";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.adminGroup} = {};
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = "Filebrowser Quantum";
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/oidc/callback"
        ];
      };

      # Filebrowser-Quantum doesn't support blocking access to users that aren't part of a group, so we have to do it on Authelia level
      settings.identity_providers.oidc.authorization_policies.${name} = {
        default_policy = "deny";
        rules = [
          {
            policy = config.nps.stacks.authelia.defaultAllowPolicy;
            subject = [
              "group:${cfg.oidc.adminGroup}"
              "group:${cfg.oidc.userGroup}"
            ];
          }
        ];
      };
    };

    nps.stacks.filebrowser-quantum.settings = {
      server = {
        port = 80;
        baseURL = "/";
        externalUrl = config.nps.containers.${name}.traefik.serviceUrl;
        logging = [
          {levels = "warning";}
        ];
        sources = lib.attrValues cfg.mounts;
      };

      userDefaults = {
        preview = {
          image = true;
          popup = true;
          video = false;
          office = false;
          highQuality = false;
        };
        darkMode = true;
        disableSettings = false;
        singleClick = false;
        permissions = {
          admin = false;
          modify = false;
          share = false;
          api = false;
        };
      };
      auth.methods.oidc = {
        enabled = cfg.oidc.enable;
        clientId = name;
        issuerUrl = config.nps.containers.authelia.traefik.serviceUrl;
        scopes = "email openid profile groups";
        userIdentifier = "preferred_username";
        disableVerifyTLS = false;
        logoutRedirectUrl = "";
        createUser = true;
        adminGroup = cfg.oidc.adminGroup;
        groupsClaim = "groups";
      };
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/gtsteffaniak/filebrowser:0.8.9-beta";
      volumes =
        [
          "${yaml.generate "config.yml" cfg.settings}:/home/filebrowser/config.yml"
          "${storage}/db:/home/filebrowser/db"
        ]
        ++ lib.mapAttrsToList (k: v: "${k}:${v.path}") cfg.mounts;

      extraEnv = {
        FILEBROWSER_CONFIG = "/home/filebrowser/config.yml";
        FILEBROWSER_DATABASE = "/home/filebrowser/db/database.db";
        FILEBROWSER_OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
      };
      port = 80;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "filebrowser-quantum";
        };
      };
      glance = {
        inherit category description;
        id = name;
        name = displayName;
        icon = "di:filebrowser-quantum";
      };
    };
  };
}
