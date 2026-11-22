{dummySecretFile, ...}: {
  # The backend joins the Traefik network unconditionally.
  imports = [../../traefik/vm-tests/default.nix];
  nps.stacks.homelable = {
    enable = true;
    secretKeyFile = dummySecretFile;
    auth.passwordHashFile = dummySecretFile;
  };
}
