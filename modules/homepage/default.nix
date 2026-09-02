{
  config,
  pkgs,
  lib,
  ...
}: let
  name = "homepage";
  externalStorage = config.nps.externalStorageBaseDir;
  cfg = config.nps.stacks.${name};
  yaml = pkgs.formats.yaml {};

  category = "Network & Administration";
  displayName = "Homepage";
  description = "Dashboard";

  utils = import ./utils.nix lib;

  deepFilterWidgets = value:
    if lib.isAttrs value
    then
      lib.filterAttrs (n: v: !(n == "widget" && !(v.enable or false))) (
        lib.mapAttrs (_: deepFilterWidgets) value
      )
    else if lib.isList value
    then builtins.map deepFilterWidgets value
    else value;

  # Replace paths values in the configuration with environment variable placeholders
  bookmarks = utils.replacePathsDeep cfg.bookmarks |> yaml.generate "bookmarks";
  services = utils.replacePathsDeep cfg.services |> deepFilterWidgets |> yaml.generate "services";
  settings = utils.replacePathsDeep cfg.settings |> yaml.generate "settings";
  widgets = utils.replacePathsDeep cfg.widgets |> yaml.generate "widgets";
  docker = utils.replacePathsDeep cfg.docker |> yaml.generate "docker";

  # Extract path entries from the configuration to be used as environment variables
  # Will be used to pass environment variables & corresponding paths as volumes to the container
  pathEntries =
    [
      cfg.bookmarks
      cfg.docker
      cfg.services
      cfg.settings
      cfg.widgets
    ]
    |> map utils.pathEntries
    |> lib.foldl' (a: b: a // b) {};

  sortByRank = attrs:
    builtins.sort (
      a: b: let
        orderA = attrs.${a}.rank or 999;
        orderB = attrs.${b}.rank or 999;
      in
        if orderA == orderB
        then (lib.strings.toLower a) < (lib.strings.toLower b)
        else orderA < orderB
    ) (builtins.attrNames attrs);

  toOrderedList = attrs:
    builtins.map (groupName: {
      "${groupName}" = builtins.map (serviceName: {
        "${serviceName}" = attrs.${groupName}.${serviceName};
      }) (sortByRank attrs.${groupName});
    }) (sortByRank attrs);
in {
  imports =
    [
      ./extension.nix
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
    ]
    ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable =
      lib.mkEnableOption name
      // {
        description = ''
          Whether to enable the Homepage stack.

          The services of enabled stacks will be automatically added to Homepage.
          The module will also automatically configure the docker integration for the local host and
          setup some widgets.
        '';
      };
    bookmarks = lib.mkOption {
      inherit (yaml) type;
      description = ''
        Homepage bookmarks configuration.

        See <https://gethomepage.dev/configs/bookmarks/>.
      '';
      example = [
        {
          Developer = [
            {
              Github = [
                {
                  abbr = "GH";
                  href = "https://github.com/";
                }
              ];
            }
          ];
        }
        {
          Entertainment = [
            {
              YouTube = [
                {
                  abbr = "YT";
                  href = "https://youtube.com/";
                }
              ];
            }
          ];
        }
      ];
      default = [];
    };
    services = lib.mkOption {
      inherit (yaml) type;
      apply = services: toOrderedList services;
      description = ''
        Homepage services configuration.

        See <https://gethomepage.dev/configs/services/>.
      '';
      example = {
        "My First Group" = {
          "My First Service" = {
            href = "http://localhost/";
            description = "Some Service";
          };
        };
        "My Second Group" = {
          "My Second Service" = {
            href = "http://localhost/";
            description = "Some other Service";
          };
        };
      };

      default = {};
    };
    widgets = lib.mkOption {
      inherit (yaml) type;
      description = ''
        Homepage widgets configuration.

        See <https://gethomepage.dev/widgets/>.
      '';
      example = [
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
          };
        }
        {
          search = {
            provider = "duckduckgo";
            target = "_blank";
          };
        }
      ];
      default = [];
    };
    docker = lib.mkOption {
      inherit (yaml) type;
      description = ''
        Homepage docker configuration.

        See <https://gethomepage.dev/configs/docker/>.
      '';
      default = {};
    };
    settings = lib.mkOption {
      inherit (yaml) type;
      description = ''
        Homepage settings.

        See <https://gethomepage.dev/configs/settings/>.
      '';
      default = {};
    };
    authSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the auth secret. Only required if OIDC Is enabled.
        You can generate a secret using `openssl rand -base64 32.

        See <https://gethomepage.dev/installation/#security-authentication>
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

          - <https://gethomepage.dev/installation/#security-authentication>
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
          "${cfg.containers.${name}.traefik.serviceUrl}/api/auth/callback/homepage-oidc"
        ];
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
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/gethomepage/homepage:v2.2.0";
      volumeMap = {
        ext = "${externalStorage}:/ext:ro";
        docker = "${docker}:/app/config/docker.yaml";
        services = "${services}:/app/config/services.yaml";
        settings = "${settings}:/app/config/settings.yaml";
        widgets = "${widgets}:/app/config/widgets.yaml";
        bookmarks = "${bookmarks}:/app/config/bookmarks.yaml";
      };

      extraEnv =
        {
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          HOMEPAGE_ALLOWED_HOSTS = config.services.podman.containers.${name}.traefik.serviceHost;
        }
        // lib.optionalAttrs cfg.oidc.enable {
          HOMEPAGE_AUTH_ENABLED = true;
          HOMEPAGE_AUTH_SECRET.fromFile = cfg.authSecretFile;

          HOMEPAGE_EXTERNAL_URL = config.services.podman.containers.${name}.traefik.serviceUrl;
          HOMEPAGE_OIDC_ISSUER = config.nps.containers.authelia.traefik.serviceUrl;
          HOMEPAGE_OIDC_CLIENT_ID = name;
          HOMEPAGE_OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
          HOMEPAGE_OIDC_NAME = "Authelia";
        };
      fileEnvMount = pathEntries;

      port = 3000;
      traefik = {
        inherit name;
        subDomain = lib.mkDefault "";
      };

      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:homepage.png";
      };
    };

    nps.stacks.${name} = {
      docker.local =
        if cfg.useSocketProxy
        then {
          host = "docker-socket-proxy";
          port = config.nps.stacks.docker-socket-proxy.port;
        }
        else {socket = "/var/run/docker.sock";};
      settings.statusStyle = "dot";
      settings.useEqualHeights = true;

      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            label = "System";
          };
        }
        {
          resources = {
            disk = "/";
            label = "Storage";
          };
        }
        {
          resources = {
            disk = "/ext";
            label = "External";
          };
        }
        {
          search = {
            provider = "google";
            focus = false;
            target = "_blank";
          };
        }
      ];
    };
  };
}
