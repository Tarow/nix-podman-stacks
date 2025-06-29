let
  modules = {
    settings = ./settings.nix;
    adguard = ./adguard;
    aiostreams = ./aiostreams;
    audiobookshelf = ./audiobookshelf;
    blocky = ./blocky;
    calibre = ./calibre;
    changedetection = ./changedetection;
    crowdsec = ./crowdsec;
    dockdns = ./dockdns;
    dozzle = ./dozzle;
    filebrowser = ./filebrowser;
    healthchecks = ./healthchecks;
    homepage = ./homepage;
    immich = ./immich;
    mealie = ./mealie;
    monitoring = ./monitoring;
    paperless = ./paperless;
    stirling-pdf = ./stirling-pdf;
    streaming = ./streaming;
    traefik = ./traefik;
    uptime-kuma = ./uptime-kuma;
    wg-easy = ./wg-easy;
  };
in
  modules
  // {
    all = {imports = builtins.attrValues modules;};
  }
