{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "bambuddy";
  orcaName = "${name}-orca-slicer";
  bambuName = "${name}-bambu-studio";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "General";
  description = "3D Printer Management";
  displayName = "Bambuddy";
  icon = "https://raw.githubusercontent.com/maziggy/bambuddy/v1.2.5.7/static/img/bambuddy_logo_dark_transparent.png";
  roleGroups = [cfg.oidc.adminGroup cfg.oidc.operatorGroup cfg.oidc.viewerGroup];
in {
  imports = import ../mkAliases.nix config lib name [name orcaName bambuName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = "Extra environment variables (supports fromFile, fromTemplate, fromCommand). Overrides generated defaults.";
    };
    oidc = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to configure native OIDC login with Authelia. Authentication and a local recovery administrator must still be set up in Bambuddy.";
      };
      clientSecretFile = (import ../authelia/options.nix lib).clientSecretFile;
      clientSecretHash = (import ../authelia/options.nix lib).derivableClientSecretHash cfg.oidc.clientSecretFile;
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = "LLDAP group mapped to Bambuddy's Administrators role on SSO login.";
      };
      operatorGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_operator";
        description = "LLDAP group mapped to Bambuddy's Operators role on SSO login.";
      };
      viewerGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_viewer";
        description = "LLDAP group mapped to Bambuddy's Viewers role on SSO login.";
      };
    };
    orcaSlicer.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to run a private OrcaSlicer API sidecar. Requires x86_64 Linux and enabling Use Slicer API in Bambuddy.";
    };
    bambuStudio.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to run a private Bambu Studio API sidecar. Requires x86_64 Linux and enabling Use Slicer API in Bambuddy.";
    };
    virtualPrinter.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to publish virtual-printer TCP ports on all host interfaces and advertise nps.hostIP4Address. Requires host permission for rootless low-port binding and manual in-app setup; does not configure the firewall or guarantee proxy-mode operation.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.orcaSlicer.enable || cfg.bambuStudio.enable) || pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "Bambuddy managed OrcaSlicer and Bambu Studio sidecars require x86_64-linux. Disable them and use external slicer APIs on other architectures.";
      }
    ];

    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable (lib.genAttrs roleGroups (_: {}));

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = displayName;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = true;
        pkce_challenge_method = "S256";
        token_endpoint_auth_method = "client_secret_post";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/api/v1/auth/oidc/callback"
        ];
        scopes = ["openid" "email" "profile" "groups"];
        claims_policy = name;
      };

      settings.identity_providers.oidc = {
        claims_policies.${name}.id_token = [
          "email"
          "email_verified"
          "preferred_username"
          "name"
          "groups"
        ];
        authorization_policies.${name} = {
          default_policy = "deny";
          rules = [
            {
              policy = config.nps.stacks.authelia.defaultAllowPolicy;
              subject = map (group: "group:${group}") roleGroups;
            }
          ];
        };
      };
    };

    services.podman.containers = {
      ${name} = {
        # renovate: versioning=regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\.(?<build>\d+)$
        image = "ghcr.io/maziggy/bambuddy:1.2.5.7";
        volumeMap = {
          data = "${storage}/data:/app/data";
          logs = "${storage}/logs:/app/logs";
        };
        extraEnv =
          {
            PUID = config.nps.defaultUid;
            PGID = config.nps.defaultGid;
            APP_URL = cfg.containers.${name}.traefik.serviceUrl;
          }
          // lib.optionalAttrs cfg.oidc.enable {
            BAMBUDDY_OIDC_NAME = "Authelia";
            BAMBUDDY_OIDC_ISSUER_URL = config.nps.containers.authelia.traefik.serviceUrl;
            BAMBUDDY_OIDC_CLIENT_ID = name;
            BAMBUDDY_OIDC_CLIENT_SECRET.fromFile = cfg.oidc.clientSecretFile;
            BAMBUDDY_OIDC_SCOPES = "openid email profile groups";
            BAMBUDDY_OIDC_ENABLED = true;
            BAMBUDDY_OIDC_AUTO_CREATE_USERS = true;
            BAMBUDDY_OIDC_AUTO_LINK_EXISTING = false;
            BAMBUDDY_OIDC_AUTOLOGIN = false;
            BAMBUDDY_OIDC_REQUIRE_EMAIL_VERIFIED = true;
            BAMBUDDY_OIDC_GROUP_CLAIM = "groups";
            # Runtime environment files preserve JSON quotes that Quadlet would strip.
            BAMBUDDY_OIDC_GROUP_MAPPING.fromTemplate = builtins.toJSON {
              ${cfg.oidc.adminGroup} = "Administrators";
              ${cfg.oidc.operatorGroup} = "Operators";
              ${cfg.oidc.viewerGroup} = "Viewers";
            };
            BAMBUDDY_LOCAL_LOGIN = lib.mkDefault false;
          }
          // lib.optionalAttrs cfg.orcaSlicer.enable {
            SLICER_API_URL = "http://${orcaName}:3000";
          }
          // lib.optionalAttrs cfg.bambuStudio.enable {
            BAMBU_STUDIO_API_URL = "http://${bambuName}:3000";
          }
          // lib.optionalAttrs cfg.virtualPrinter.enable {
            VIRTUAL_PRINTER_PASV_ADDRESS = config.nps.hostIP4Address;
            VIRTUAL_PRINTER_ADVERTISE_ADDRESS = config.nps.hostIP4Address;
          }
          // cfg.extraEnv;

        wantsContainer =
          lib.optional cfg.oidc.enable "authelia"
          ++ lib.optional cfg.orcaSlicer.enable orcaName
          ++ lib.optional cfg.bambuStudio.enable bambuName;
        # Suppress the shared direct-web-port fallback when Traefik is disabled.
        ports = lib.mkOverride 90 (lib.optionals cfg.virtualPrinter.enable [
          "3000:3000/tcp"
          "3002:3002/tcp"
          "8883:8883/tcp"
          "990:990/tcp"
          "6000:6000/tcp"
          "322:322/tcp"
          "2024-2026:2024-2026/tcp"
          "50000-50100:50000-50100/tcp"
        ]);
        addCapabilities = lib.optional cfg.virtualPrinter.enable "NET_BIND_SERVICE";
        stack = name;
        port = 8000;
        traefik.name = name;
        dashboard = {
          inherit category description icon;
          name = displayName;
        };
      };

      ${orcaName} = lib.mkIf cfg.orcaSlicer.enable {
        # renovate: versioning=regex:^bambuddy-(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\.(?<build>\d+)$
        image = "ghcr.io/maziggy/orca-slicer-api:bambuddy-1.2.5.7";
        volumeMap.data = "${storage}/orca-slicer:/app/data";
        environment = {
          NODE_ENV = "production";
          PORT = 3000;
        };
        stack = name;
        dashboard = {
          inherit category icon;
          name = "OrcaSlicer";
          description = "OrcaSlicer API";
          parent = name;
        };
      };

      ${bambuName} = lib.mkIf cfg.bambuStudio.enable {
        # renovate: versioning=regex:^bambuddy-(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\.(?<build>\d+)$
        image = "ghcr.io/maziggy/bambu-studio-api:bambuddy-1.2.5.7";
        volumeMap.data = "${storage}/bambu-studio:/app/data";
        environment = {
          NODE_ENV = "production";
          PORT = 3000;
        };
        stack = name;
        dashboard = {
          inherit category icon;
          name = "Bambu Studio";
          description = "Bambu Studio API";
          parent = name;
        };
      };
    };
  };
}
