{
  upstreams = {
    groups = {
      default = [
        "5.9.164.112"
        "tcp-tls:fdns1.dismail.de:853"
        "https://dns.digitale-gesellschaft.ch/dns-query"
        "https://cloudflare-dns.com/dns-query"
      ];
    };
  };

  blocking = {
    denylists = {
      ads = [
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.txt"
      ];
    };
    clientGroupsBlock = {
      default = ["ads"];
    };
  };

  ports = {
    dns = 53;
    http = 4000;
  };
}
