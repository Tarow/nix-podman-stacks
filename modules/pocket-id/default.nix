{
  config,
  lib,
  options,
  ...
}: let
  name = "pocketid";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    env = lib.mkOption {
      type = (options.services.podman.containers.type.getSubOptions []).environment.type;
      default = {};
      description = ''
        Additional environment variables passed to the Pocket ID container
        See <https://pocket-id.org/docs/configuration/environment-variables>
      '';
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Environment file being passed to the container. Can be used to pass additional variables such
        as 'MAXMIND_LICENSE_KEY'.
        Refer to <https://pocket-id.org/docs/configuration/environment-variables/>
        for a full list of available variables
      '';
    };
    traefikIntegration = {
      envFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Environment file being passed to the Traefik container.
          If this is set, a new `pocketid` middleware will be registered in Traefik.
          In order to work, the environment file should contain the secrets
          'POCKET_ID_CLIENT_ID', 'POCKET_ID_CLIENT_SECRET' & 'OIDC_MIDDLEWARE_SECRET'

          'POCKET_ID_CLIENT_ID' and 'POCKET_ID_CLIENT_SECRET' are the credentials generated within PocketID
          for the Traefik client. 'OIDC_MIDDLEWARE_SECRET' should be a random secret.
        '';
      };
    };
    ldap = {
      enableSynchronisation = lib.mkOption {
        type = lib.types.bool;
        default = config.tarow.podman.stacks.lldap.enable;
        defaultText = lib.literalExpression ''config.tarow.stacks.lldap.enable'';
        description = ''
          Whether to sync users and groups from an the LDAP server.
          Requires the LLDAP stack to be enabled.
        '';
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = config.tarow.podman.stacks.lldap.adminUsername;
        defaultText = lib.literalExpression ''config.tarow.podman.stacks.lldap.adminUsername'';
        description = ''
          The username that will be used when binding to the LDAP backend.
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = config.tarow.podman.stacks.lldap.adminPasswordFile;
        defaultText = lib.literalExpression ''config.tarow.podman.stacks.lldap.adminPasswordFile'';
        description = ''
          The password for the LDAP user that is used when connecting to the LDAP backend.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.traefik = lib.mkIf (cfg.traefikIntegration.envFile != null) {
      containers.traefik.environmentFile = [cfg.traefikIntegration.envFile];

      staticConfig.experimental.plugins.traefik-oidc-auth = {
        moduleName = "github.com/sevensolutions/traefik-oidc-auth";
        version = "v0.14.0";
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
      image = "ghcr.io/pocket-id/pocket-id:v1.7.0";
      volumes =
        [
          "${storage}/data:/app/data"
        ]
        ++ lib.optional cfg.ldap.enableSynchronisation "${cfg.ldap.passwordFile}:/secrets/ldap_password";

      environment =
        {
          PUID = config.tarow.podman.defaultUid;
          PGID = config.tarow.podman.defaultGid;
          TRUST_PROXY = true;
          APP_URL = cfg.containers.${name}.traefik.serviceDomain;
          ANALYTICS_DISABLED = true;
        }
        // lib.optionalAttrs cfg.ldap.enableSynchronisation (
          let
            lldap = config.tarow.podman.stacks.lldap;
          in {
            UI_CONFIG_DISABLED = true;
            LDAP_ENABLED = true;
            LDAP_URL = lldap.address;
            LDAP_BASE = lldap.baseDn;
            LDAP_BIND_DN = "CN=${cfg.ldap.user},OU=people," + lldap.baseDn;
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
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

      port = 1411;
      traefik.name = name;
      homepage = {
        category = "Network & Administration";
        name = "Pocket ID";
        settings = {
          description = "Simple OIDC Provider";
          icon = "pocket-id";
        };
      };
    };
  };
}
