{
  lib,
  dummySecretFile,
  dummyRsaKeyFile,
  ...
}: {
  imports = [../lldap/vm-test.nix];
  # Authelia references the Traefik domain for its session cookies, even when
  # Traefik itself is not part of the test.
  nps.stacks.traefik.domain = "example.com";
  nps.stacks.authelia = {
    enable = true;
    jwtSecretFile = dummySecretFile;
    sessionSecretFile = dummySecretFile;
    storageEncryptionKeyFile = dummySecretFile;
    oidc = {
      enable = true;
      hmacSecretFile = dummySecretFile;
      jwksRsaKeyFile = dummyRsaKeyFile;
      clients.dummy = {
        public = true;
        authorization_policy = "two_factor";
        redirect_uris = [];
      };
    };
    # Without Traefik the module's default `authelia_url` would be an insecure
    # `http://<ip>:<port>` URL, which Authelia rejects for session cookies.
    settings.session.cookies = lib.mkForce [
      {
        domain = "example.com";
        authelia_url = "https://authelia.example.com";
        name = "authelia_session";
      }
    ];
  };
  # In production Traefik puts Authelia and LLDAP on the same network. Without
  # Traefik in this test, connect Authelia to the LLDAP network so it can
  # resolve the `lldap` hostname.
  services.podman.containers.lldap.stack = "lldap";
  services.podman.containers.authelia.network = ["lldap"];
}
