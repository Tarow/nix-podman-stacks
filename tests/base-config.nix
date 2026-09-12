{
  home-manager,
  pkgs,
  self,
  stackTestModule,
  ...
}: {
  imports = [
    home-manager.nixosModules.home-manager
  ];

  environment.etc."nps-test/check.sh".source = ./check.sh;

  # rootless Podman requires subuid/subgid mappings
  users.users.ci = {
    isNormalUser = true;
    uid = 1000;
    description = "Integration test user";
    shell = pkgs.bash;
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  # Stack under test (merged with base-home.nix).
  home-manager = {
    useGlobalPkgs = true;
    users.ci = {...}: {
      imports = [
        self.homeModules.nps
        ./base-home.nix
        stackTestModule
      ];
    };
  };

  security.allowUserNamespaces = true;
  boot.kernel.sysctl = {
    # Allow unprivileged binding of low ports (adguard 53/853, forgejo 22)
    "net.ipv4.ip_unprivileged_port_start" = 22;
  };

  # QEMU user networking provides DNS via the host through 10.0.2.3
  networking.nameservers = ["10.0.2.3"];

  # Storage mount point for media stacks (rootless podman can't create /mnt).
  systemd.tmpfiles.rules = [
    "d /mnt/media 0755 ci ci -"
  ];

  # Podman waits for network-online.target at startup. Pull it in to avoid a 90s timeout.
  systemd.targets.network-online.wantedBy = ["multi-user.target"];

  virtualisation = {
    memorySize = 2048;
    diskSize = 8192;
  };

  system.stateVersion = "26.05";
}
