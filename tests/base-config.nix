# Central NixOS-side configuration for VM integration tests.
# Merged together with a per-stack `vm-test.nix` (see `tests/vm.nix`).
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

  # Make the verification script available inside the VM
  environment.etc."nps-test/check.sh".source = ./check.sh;

  # Test user running rootless Podman.
  # Needs subuids/subgids for user namespace mapping.
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

  # Merge the base home setup with the stack under test.
  # This is activated as part of system activation, so the stack is deployed
  # exactly like on a real machine (Quadlets are written and units are enabled).
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

  # Rootless Podman requirements
  security.allowUserNamespaces = true;
  boot.kernel.sysctl = {
    # Allow unprivileged processes to bind ports 80/443 (Traefik socket activation)
    "net.ipv4.ip_unprivileged_port_start" = 80;
  };

  # QEMU user networking provides DNS via the host through 10.0.2.3
  networking.nameservers = ["10.0.2.3"];

  # Rootless podman cannot create /mnt as user `ci`; ensure the external
  # storage mount point exists (needed by media/external-storage stacks).
  systemd.tmpfiles.rules = [
    "d /mnt/media 0755 ci ci -"
  ];

  # NixOS "classic" (dhcpcd) networking never activates the passive
  # network-online.target by itself, because no system service wants it.
  # However, podman's `podman-user-wait-network-online.service` blocks on
  # `systemctl is-active network-online.target` and would otherwise time out
  # after 90s, delaying the whole stack. Pull the target in explicitly, so
  # containers start as soon as dhcpcd has configured the interfaces.
  systemd.targets.network-online.wantedBy = ["multi-user.target"];

  virtualisation = {
    memorySize = 2048;
    diskSize = 8192;
  };

  system.stateVersion = "26.05";
}
