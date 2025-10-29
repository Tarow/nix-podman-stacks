{
  config,
  lib,
  options,
  ...
}: let
  name = "pocketid";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Network & Administration";
  description = "Simple OIDC Provider";
  displayName = "Pocket ID";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    env = lib.mkOption {
      type = (options.services.podman.containers.type.getSubOptions []).environment.type;
      default = {};
      description = ''
        Additional environment variables passed to the Pocket ID container
        See <https://pocket-id.org/docs/configuration/environment-variables>
      '';
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://pocket-id.org/docs/configuration/environment-variables>
      '';
      example = {
        MAXMIND_LICENSE_KEY = {
          fromFile = "/run/secrets/maxmind_key";
        };
        FOO = "bar";
      };
    };
    traefikIntegration = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.nps.stacks.traefik.enable;
        defaultText = lib.literalExpression ''config.nps.stacks.traefik.enable'';
        description = ''
          Whether to setup a `pocketid` middleware in Traefik.
          The middleware will use the <https://github.com/sevensolutions/traefik-oidc-auth> plugin to secure upstream services.
        '';
      };
      clientId = lib.mkOption {
        type = lib.types.str;
        description = ''
          The client ID used by the Traefik OIDC middleware.
        '';
        example = "traefik";
      };
      clientSecretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the client secret used by the Traefik OIDC middleware.
        '';
      };
      encryptionSecretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          The file containing the encryption secret used by the Traefik OIDC middleware.
          This should be a random secret.

          See <https://traefik-oidc-auth.sevensolutions.cc/docs/getting-started/middleware-configuration>
        '';
      };
    };
    ldap = {
      enableSynchronisation = lib.mkOption {
        type = lib.types.bool;
        default = config.nps.stacks.lldap.enable;
        defaultText = lib.literalExpression ''config.nps.stacks.lldap.enable'';
        description = ''
          Whether to sync users and groups from an the LDAP server.
          Requires the LLDAP stack to be enabled.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = config.nps.stacks.lldap.adminUsername;
        defaultText = lib.literalExpression ''config.nps.stacks.lldap.adminUsername'';
        description = ''
          The username that will be used when binding to the LDAP backend.
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = config.nps.stacks.lldap.adminPasswordFile;
        defaultText = lib.literalExpression ''config.nps.stacks.lldap.adminPasswordFile'';
        description = ''
          The password for the LDAP user that is used when connecting to the LDAP backend.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.containers.traefik = lib.mkIf cfg.traefikIntegration.enable {
      wantsContainer = [name];
      environment = {
        POCKET_ID_CLIENT_ID = cfg.traefikIntegration.clientId;
      };
      extraEnv = {
        POCKET_ID_CLIENT_SECRET.fromFile = cfg.traefikIntegration.clientSecretFile;
        OIDC_MIDDLEWARE_SECRET.fromFile = cfg.traefikIntegration.encryptionSecretFile;
      };
    };
    nps.stacks.traefik = lib.mkIf cfg.traefikIntegration.enable {
      staticConfig.experimental.plugins.traefik-oidc-auth = {
        moduleName = "github.com/sevensolutions/traefik-oidc-auth";
        version = "v0.16.0";
      };
      dynamicConfig.http.middlewares = {
        pocketid.plugin.traefik-oidc-auth = {
          Secret = ''{{env "OIDC_MIDDLEWARE_SECRET"}}'';
          Provider = {
            Url = "http://${name}:1411";
            ClientId = ''{{env "POCKET_ID_CLIENT_ID"}}'';
            ClientSecret = ''{{env "POCKET_ID_CLIENT_SECRET"}}'';
          };
          Scopes = [
            "openid"
            "profile"
            "email"
          ];
        };
      };
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/pocket-id/pocket-id:v1.14.2";
      volumes =
        [
          "${storage}/data:/app/data"
        ]
        ++ lib.optional cfg.ldap.enableSynchronisation "${cfg.ldap.passwordFile}:/secrets/ldap_password";

      environment =
        {
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          TRUST_PROXY = true;
          APP_URL = cfg.containers.${name}.traefik.serviceUrl;
          ANALYTICS_DISABLED = true;
        }
        // lib.optionalAttrs cfg.ldap.enableSynchronisation (
          let
            lldap = config.nps.stacks.lldap;
          in {
            UI_CONFIG_DISABLED = true;
            LDAP_ENABLED = true;
            LDAP_URL = lldap.address;
            LDAP_BASE = lldap.baseDn;
            LDAP_BIND_DN = "CN=${cfg.ldap.username},OU=people," + lldap.baseDn;
            LDAP_ATTRIBUTE_USER_UNIQUE_IDENTIFIER = "uuid";
            LDAP_ATTRIBUTE_USER_USERNAME = "uid";
            LDAP_ATTRIBUTE_USER_EMAIL = "mail";
            LDAP_ATTRIBUTE_USER_FIRST_NAME = "firstname";
            LDAP_ATTRIBUTE_USER_LAST_NAME = "lastname";
            LDAP_ATTRIBUTE_USER_PROFILE_PICTURE = "avatar";
            LDAP_ATTRIBUTE_GROUP_MEMBER = "member";
            LDAP_ATTRIBUTE_GROUP_UNIQUE_IDENTIFIER = "uuid";
            LDAP_ATTRIBUTE_GROUP_NAME = "cn";
            LDAP_BIND_PASSWORD_FILE = "/secrets/ldap_password";
          }
        );
      extraEnv = cfg.extraEnv;

      port = 1411;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "pocket-id";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:pocket-id";
      };
    };
  };
}
