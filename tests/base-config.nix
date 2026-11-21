# NixOS base configuration for integration test VMs. Provides everything rootless
# Podman (Quadlet) needs: an unprivileged user with subuid/subgid ranges, user
# namespaces and low port binding. See tests/check.sh and tests/driver.py for the
# verification logic.
{
  home-manager,
  self,
}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.npsTest;
  containerUnits = map (name: "podman-${name}.service") (
    lib.attrNames config.home-manager.users.ci.services.podman.containers
  );
  units = lib.unique (
    (
      if cfg.expectedUnits == null
      then containerUnits
      else cfg.expectedUnits
    )
    ++ cfg.extraExpectedUnits
  );
in {
  options.npsTest = {
    homeManagerModules = lib.mkOption {
      type = lib.types.listOf lib.types.raw;
      default = [];
      example = lib.literalExpression "[./stacks.nix]";
      description = ''
        Home Manager modules for the `ci` test user. They are imported after the base
        home configuration, so they can both enable stacks and override their options.
      '';
    };

    expectedUnits = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      example = ["my-custom.service"];
      description = ''
        Systemd user units that must reach a stable `active (running)` state.
        When `null` (the default), the units are derived from the podman containers
        of the test user. Set it to an explicit list to take full control, or to `[]`
        to skip the unit check entirely.
      '';
    };

    extraExpectedUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["my-setup.service"];
      description = "Additional units to append to `npsTest.expectedUnits`.";
    };

    waitTimeout = lib.mkOption {
      type = lib.types.int;
      default = 600;
      description = ''
        Seconds all expected units share to reach `active (running)`. This is a
        single budget for all units, not a per-unit timeout.
      '';
    };

    stabilityGrace = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = ''
        Seconds an already running unit must stay up without restarting before the
        test considers it stable.
      '';
    };

    diskSize = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Disk size of the integration test VM in MiB.";
    };

    memorySize = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = ''
        Memory size of the integration test VM in MiB. `null` uses the
        `npsTests.memorySize` Home Manager option, which is where a stack's
        `vm-tests/default.nix` or scenario file states its requirement.
      '';
    };
  };

  imports = [
    home-manager.nixosModules.home-manager
  ];

  config = {
    environment.etc = {
      "nps-test/check.sh".source = ./check.sh;

      "nps-test/check.conf".text = ''
        WAIT_TIMEOUT=${toString cfg.waitTimeout}
        STABILITY_GRACE=${toString cfg.stabilityGrace}
      '';

      "nps-test/expected-units".text = lib.concatStringsSep "\n" units;
    };

    warnings = lib.optional (cfg.expectedUnits == null && containerUnits == []) ''
      npsTest: the test user has no podman containers, so no systemd units will be
      checked. Set `npsTest.expectedUnits` explicitly if this is not intended.
    '';

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

    users.groups.ci = {
      gid = 1000;
    };

    # Stack under test (merged with base-home.nix).
    home-manager = {
      useGlobalPkgs = true;
      # Inert values, so a test module can be written without wiring up a real secret
      # backend. See tests/dummy-values.nix. NEVER use these in a real deployment.
      extraSpecialArgs = import ./dummy-values.nix pkgs;
      users.ci = {...}: {
        imports =
          [
            self.homeModules.nps
            ./base-home.nix
          ]
          ++ cfg.homeManagerModules;
      };
    };

    security.allowUserNamespaces = true;
    # Preload wireguard so rootless containers (wg-easy, wg-portal) can create `type wireguard` interfaces.
    boot.kernelModules = ["wireguard"];
    boot.kernel.sysctl = {
      # Allow unprivileged binding of low ports (adguard 53/853, forgejo 22, ftp 21, ...)
      "net.ipv4.ip_unprivileged_port_start" = 0;
    };

    # QEMU user networking provides DNS via the host through 10.0.2.3
    networking.nameservers = ["10.0.2.3"];

    # Podman waits for network-online.target at startup. Pull it in to avoid a 90s timeout.
    systemd.targets.network-online.wantedBy = ["multi-user.target"];

    virtualisation = {
      memorySize = lib.mkDefault (
        if cfg.memorySize != null
        then cfg.memorySize
        else config.home-manager.users.ci.npsTests.memorySize
      );
      diskSize = lib.mkDefault cfg.diskSize;
    };

    system.stateVersion = "26.05";
  };
}
