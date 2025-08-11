{
  config,
  lib,
  ...
}: let
  name = "audiobookshelf";
  storage = "${config.tarow.podman.storageBaseDir}/${name}";
  mediaStorage = config.tarow.podman.mediaStorageBaseDir;
  cfg = config.tarow.podman.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
    enable = lib.mkEnableOption name;
    authelia = {
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
    };
  };

  config = lib.mkIf cfg.enable {
    tarow.podman.stacks.authelia.oidc.clients.audiobookshelf = lib.mkIf cfg.authelia.registerClient {
      client_name = "Audiobookshelf";
      client_secret = cfg.authelia.clientSecretHash;
      public = false;
      authorization_policy = "one_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";
      pre_configured_consent_duration = "1 month";
      redirect_uris = [
        "${cfg.containers.${name}.traefik.serviceDomain}/auth/openid/callback"
        "${cfg.containers.${name}.traefik.serviceDomain}/auth/openid/mobile-redirect"
        "audiobookshelf://oauth"
      ];
    };

    services.podman.containers.${name} = {
      image = "ghcr.io/advplyr/audiobookshelf:2.28.0";
      volumes = [
        "${mediaStorage}/audiobooks:/audiobooks"
        "${storage}/podcasts:/podcasts"
        "${storage}/metadata:/metadata"
        "${storage}/config:/config"
      ];
      port = 80;
      traefik.name = name;
      homepage = {
        category = "Media & Downloads";
        name = "Audiobookshelf";
        settings = {
          description = "Audiobook & Podcast Server";
          icon = "audiobookshelf";
          widget.type = "audiobookshelf";
        };
      };
    };
  };
}
