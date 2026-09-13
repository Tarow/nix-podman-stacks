{
  dummySecretFile,
  dummyRsaKeyFile,
  ...
}: {
  imports = [
    ../traefik/vm-test.nix
    ../lldap/vm-test.nix
  ];
  # Traefik provides the `authelia.example.com` URL (with a self-signed
  # certificate) that Authelia's session cookies and OIDC issuer rely on.
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
  };
}
