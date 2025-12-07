let
  modules = {
    settings = ./settings.nix;
    adguard = ./adguard;
    aiostreams = ./aiostreams;
    audiobookshelf = ./audiobookshelf;
    authelia = ./authelia;
    baikal = ./baikal;
    bentopdf = ./bentopdf;
    beszel = ./beszel;
    blocky = ./blocky;
    booklore = ./booklore;
    bytestash = ./bytestash;
    calibre = ./calibre;
    changedetection = ./changedetection;
    crowdsec = ./crowdsec;
    davis = ./davis;
    dockdns = ./dockdns;
    donetick = ./donetick;
    dozzle = ./dozzle;
    docker-socket-proxy = ./docker-socket-proxy;
    ephemera = ./ephemera;
    filebrowser = ./filebrowser;
    filebrowser-quantum = ./filebrowser-quantum;
    flaresolverr = ./flaresolverr;
    forgejo = ./forgejo;
    free-games-claimer = ./free-games-claimer;
    freshrss = ./freshrss;
    gatus = ./gatus;
    glance = ./glance;
    guacamole = ./guacamole;
    healthchecks = ./healthchecks;
    homeassistant = ./homeassistant;
    homepage = ./homepage;
    hortusfox = ./hortusfox;
    immich = ./immich;
    ittools = ./it-tools;
    karakeep = ./karakeep;
    kimai = ./kimai;
    kitchenowl = ./kitchenowl;
    komga = ./komga;
    lldap = ./lldap;
    mazanoke = ./mazanoke;
    mealie = ./mealie;
    memos = ./memos;
    microbin = ./microbin;
    monitoring = ./monitoring;
    n8n = ./n8n;
    networking-toolbox = ./networking-toolbox;
    ntfy = ./ntfy;
    omnitools = ./omnitools;
    outline = ./outline;
    pangolin-newt = ./pangolin-newt;
    paperless = ./paperless;
    pocketid = ./pocket-id;
    romm = ./romm;
    sshwifty = ./sshwifty;
    stirling-pdf = ./stirling-pdf;
    storyteller = ./storyteller;
    streaming = ./streaming;
    tandoor = ./tandoor;
    timetracker = ./timetracker;
    traefik = ./traefik;
    tsbridge = ./tsbridge;
    uptime-kuma = ./uptime-kuma;
    vaultwarden = ./vaultwarden;
    vikunja = ./vikunja;
    webtop = ./webtop;
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
