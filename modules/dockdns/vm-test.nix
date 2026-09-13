{dummySecretFile, ...}: {
  imports = [
    ../docker-socket-proxy/vm-test.nix
    ../traefik/vm-test.nix
  ];
  nps.stacks.dockdns = {
    enable = true;
    useSocketProxy = true;
    extraEnv = {
      EXAMPLE_COM_API_TOKEN.fromFile = dummySecretFile;
      EXAMPLE_COM_ZONE_ID = "example-zone-id";
    };
    settings.dns.purgeUnknown = false;
  };
}
