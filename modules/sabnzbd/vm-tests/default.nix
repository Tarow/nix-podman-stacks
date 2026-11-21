{...}: {
  nps.stacks.sabnzbd = {
    enable = true;
    configIni = ''
      [misc]
      host_whitelist_entry = sabnzbd.example.com
    '';
  };
}
