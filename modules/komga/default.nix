{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "komga";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
  yaml = pkgs.formats.yaml {};

  category = "Media & Downloads";
  description = "Ebook Media Server";
  displayName = "Komga";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = yaml.type;
      default = {};
      apply = yaml.generate "application.yml";
      description = ''
        Additional settings that will be provided as the `application.yml` file.

        See <https://komga.org/docs/installation/configuration/>
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

          - <https://www.authelia.com/integration/openid-connect/clients/komga/>
          - <https://komga.org/docs/installation/oauth2#advanced-configuration>
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
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = "Users must be a part of this group to be able to log in.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.enable {
      ${cfg.oidc.userGroup} = {};
    };

    nps.stacks.authelia = lib.mkIf cfg.oidc.enable {
      oidc.clients.${name} = {
        client_name = lib.toSentenceCase name;
        client_secret = cfg.oidc.clientSecretHash;
        public = false;
        authorization_policy = name;
        require_pkce = false;
        pkce_challenge_method = "";
        pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
        redirect_uris = [
          "${cfg.containers.${name}.traefik.serviceUrl}/login/oauth2/code/authelia"
        ];
      };
      # No real RBAC control based on custom claims / groups yet. Restrict user-access on Authelia level.
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

    nps.stacks.${name}.settings = lib.mkIf cfg.oidc.enable {
      komga.oauth2-account-creation = true;
      spring.security.oauth2.client = {
        registration.authelia = {
          client-id = name;
          client-secret = "\${AUTHELIA_CLIENT_SECRET}";
          client-name = "Authelia";
          scope = "openid,profile,email";
          authorization-grant-type = "authorization_code";
          redirect-uri = "{baseScheme}://{baseHost}{basePort}{basePath}/login/oauth2/code/authelia";
        };
        provider.authelia = {
          issuer-uri = config.nps.containers.authelia.traefik.serviceUrl;
          user-name-attribute = "preferred_username";
        };
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/gotson/komga:1.23.6";
        user = "${toString config.nps.defaultUid}:${toString config.nps.defaultGid}";
        volumes = [
          "${storage}/data:/data"
          "${storage}/config:/config"
          "${cfg.settings}:/config/application.yml"
        ];

        extraEnv = {
          AUTHELIA_CLIENT_SECRET = lib.mkIf (cfg.oidc.enable) {fromFile = cfg.oidc.clientSecretFile;};
        };

        port = 25600;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "komga";
            widget.type = "komga";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:komga";
        };
      };
    };
  };
}
