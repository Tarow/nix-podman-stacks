{
  pkgs,
  dummySecretFile,
  ...
}: let
  # wg-easy 15.5 pins iptables-legacy, which recent kernels no longer ship.
  # The image also contains iptables-nft; put symlinks first in PATH so the
  # default wg-quick hooks use the available backend without patching the DB.
  shimSource = pkgs.runCommand "wg-easy-nftables-shim" {} ''
    mkdir -p $out
    ln -s /usr/sbin/iptables-nft $out/iptables
    ln -s /usr/sbin/iptables-nft-save $out/iptables-save
    ln -s /usr/sbin/iptables-nft-restore $out/iptables-restore
    ln -s /usr/sbin/ip6tables-nft $out/ip6tables
    ln -s /usr/sbin/ip6tables-nft-save $out/ip6tables-save
    ln -s /usr/sbin/ip6tables-nft-restore $out/ip6tables-restore
  '';
  shimDir = "/nps-test/nftables-bin";
in {
  nps.stacks.wg-easy = {
    enable = true;
    adminUsername = "admin";
    adminPasswordFile = dummySecretFile;
    host = "192.168.1.1";
    port = 51820;
    containers.wg-easy = {
      volumeMap.nftablesShim = "${shimSource}:${shimDir}:ro";
      extraEnv.PATH = "${shimDir}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
    };
  };
}
