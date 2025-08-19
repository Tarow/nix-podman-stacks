{
  config,
  lib,
  ...
}:
{

  # !IMPORTANT! This is just for demo purposes.
  # In a real setup, place your age key in any location and refer to it in
  # the `sops.age.keyFile` option. Make sure it's not in the Nix store!
  xdg.configFile."nps-demo/keys.txt".source = ./keys.txt;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";

    # Path to your age key. Typically places at ~/.config/sops/age/keys.txt
    age.keyFile = "${config.home.homeDirectory}/.config/nps-demo/keys.txt";

    # Make sure to declare all secrets here that are part of your
    # `secrets.yaml` and that you refer to in the config
    secrets = lib.genAttrs [
      "authelia/jwt_secret"
      "authelia/session_secret"
      "authelia/encryption_key"
      "authelia/oidc_hmac_secret"
      "authelia/oidc_rsa_pk"
      "crowdsec/traefik_bouncer_key"
      "immich/authelia_client_secret"
      "immich/db_password"
      "lldap/key_seed"
      "lldap/jwt_secret"
      "lldap/admin_password"
      "lldap/john_password"
      "paperless/secret_key"
      "paperless/authelia_client_secret"
      "paperless/db_password"
      "traefik/cf_api_token"
    ] (s: { });
  };
}
