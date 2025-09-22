let
  modules = {
    settings = ./settings.nix;
    adguard = ./adguard;
    aiostreams = ./aiostreams;
    audiobookshelf = ./audiobookshelf;
    authelia = ./authelia;
    baikal = ./baikal;
    beszel = ./beszel;
    blocky = ./blocky;
    bytestash = ./bytestash;
    calibre = ./calibre;
    changedetection = ./changedetection;
    crowdsec = ./crowdsec;
    davis = ./davis;
    dockdns = ./dockdns;
    donetick = ./donetick;
    dozzle = ./dozzle;
    docker-socket-proxy = ./docker-socket-proxy;
    filebrowser = ./filebrowser;
    filebrowser-quantum = ./filebrowser-quantum;
    forgejo = ./forgejo;
    freshrss = ./freshrss;
    gatus = ./gatus;
    glance = ./glance;
    guacamole = ./guacamole;
    healthchecks = ./healthchecks;
    homeassistant = ./homeassistant;
    homepage = ./homepage;
    immich = ./immich;
    ittools = ./it-tools;
    karakeep = ./karakeep;
    kimai = ./kimai;
    komga = ./komga;
    lldap = ./lldap;
    mazanoke = ./mazanoke;
    mealie = ./mealie;
    memos = ./memos;
    microbin = ./microbin;
    monitoring = ./monitoring;
    n8n = ./n8n;
    ntfy = ./ntfy;
    omnitools = ./omnitools;
    outline = ./outline;
    paperless = ./paperless;
    pocketid = ./pocket-id;
    romm = ./romm;
    sshwifty = ./sshwifty;
    stirling-pdf = ./stirling-pdf;
    storyteller = ./storyteller;
    streaming = ./streaming;
    traefik = ./traefik;
    uptime-kuma = ./uptime-kuma;
    vaultwarden = ./vaultwarden;
    vikunja = ./vikunja;
    wg-easy = ./wg-easy;
    wg-portal = ./wg-portal;
  };
in
  modules
  // {
    nps = {
      imports = builtins.attrValues modules;
    };
  }
