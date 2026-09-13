{pkgs, ...}: let
  # duckdns validates tokens against a UUID-shaped regex, so generate a lowercase UUID (no trailing newline).
  duckdnsTokenFile = pkgs.runCommand "ddns-updater-duckdns-token" {
    nativeBuildInputs = [pkgs.util-linux];
  } "printf '%s' \"$(uuidgen | tr '[:upper:]' '[:lower:]')\" > $out";
in {
  nps.stacks.ddns-updater = {
    enable = true;
    settings = [
      {
        provider = "duckdns";
        domain = "example.duckdns.org";
        token = "{{ file.Read `${duckdnsTokenFile}`}}";
        ip_version = "ipv4";
      }
    ];
    extraEnv.BACKUP_PERIOD = "72h";
  };
}
