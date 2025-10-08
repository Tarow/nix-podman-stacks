{
  config,
  lib,
  ...
}: let
  name = "audiobookshelf";
  storage = "${config.nps.storageBaseDir}/${name}";
  mediaStorage = config.nps.mediaStorageBaseDir;
  cfg = config.nps.stacks.${name};

  category = "Media & Downloads";
  displayName = "Audiobookshelf";
  description = "Audiobook & Podcast Server";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    oidc = {
      registerClient = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to register a Audiobookshelf OIDC client in Authelia.
          If enabled you need to provide a hashed secret in the `client_secret` option.

          To enable OIDC Login for Audiobookshelf, you will have to enable it in the Web UI.

          For details, see:
          - <https://www.authelia.com/integration/openid-connect/clients/audiobookshelf/>
          - <https://www.audiobookshelf.org/guides/oidc_authentication/#configuring-audiobookshelf-for-sso>
        '';
      };
      clientSecretHash = lib.mkOption {
        type = lib.types.str;
        description = ''
          The hashed client_secret.
          For examples on how to generate a client secret, see

          <https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#client-secret>
        '';
      };
      adminGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_admin";
        description = ''
          Users of this group will be assigned admin rights.

          In order to take effect, you will have to enter the value `abs_groups` in the Group Claim form field in the Audiobookshelf UI.
        '';
      };
      userGroup = lib.mkOption {
        type = lib.types.str;
        default = "${name}_user";
        description = ''
          Users of this group will be able to log in

          In order to take effect, you will have to enter the value `abs_groups` in the Group Claim form field in the Audiobookshelf UI.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.lldap.bootstrap.groups = lib.mkIf cfg.oidc.registerClient {
      ${cfg.oidc.adminGroup} = {};
      ${cfg.oidc.userGroup} = {};
    };
    nps.stacks.authelia = let
      customClaimName = "abs_groups";
    in
      lib.mkIf cfg.oidc.registerClient {
        oidc.clients.audiobookshelf = {
          client_name = "Audiobookshelf";
          client_secret = cfg.oidc.clientSecretHash;
          public = false;
          authorization_policy = config.nps.stacks.authelia.defaultAllowPolicy;
          require_pkce = true;
          pkce_challenge_method = "S256";
          pre_configured_consent_duration = config.nps.stacks.authelia.oidc.defaultConsentDuration;
          redirect_uris = [
            "${cfg.containers.${name}.traefik.serviceUrl}/auth/openid/callback"
            "${cfg.containers.${name}.traefik.serviceUrl}/auth/openid/mobile-redirect"
            "audiobookshelf://oauth"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
            # Claim-Name has to be same as scope name
            # See <https://github.com/advplyr/audiobookshelf/issues/3006>
            customClaimName
          ];
          claims_policy = name;
        };
        settings.identity_providers.oidc = {
          claims_policies.${name}.custom_claims = {
            ${customClaimName}.attribute = customClaimName;
          };
          scopes.${customClaimName}.claims = [
            customClaimName
          ];
        };
        settings.definitions.user_attributes.${customClaimName}.expression = ''"${cfg.oidc.adminGroup}" in groups ? ["admin"] : ("${cfg.oidc.userGroup}" in groups ? ["user"] : [])'';
      };

    services.podman.containers.${name} = {
      image = "ghcr.io/advplyr/audiobookshelf:2.30.0";
      volumes = [
        "${mediaStorage}/audiobooks:/audiobooks"
        "${storage}/podcasts:/podcasts"
        "${storage}/metadata:/metadata"
        "${storage}/config:/config"
      ];
      port = 80;
      traefik.name = name;

      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "audiobookshelf";
          widget.type = "audiobookshelf";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:audiobookshelf";
      };
    };
  };
}
