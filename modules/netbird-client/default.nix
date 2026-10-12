{
  config,
  lib,
  ...
}: let
  name = "netbird-client";
  cfg = config.nps.stacks.${name};

  storage = "${config.nps.storageBaseDir}/${name}";

  managementStackName = "netbird-management";
  managementServerName = "${managementStackName}-server";

  cloudManagementUrl = "https://api.netbird.io:443";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;

    setupKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing the setup key used to enroll this peer.

        Create one in the NetBird dashboard under "Peers" → "Setup Keys".
      '';
    };

    managementUrl = lib.mkOption {
      type = lib.types.str;
      default =
        if config.nps.stacks.${managementStackName}.enable
        then config.nps.stacks.${managementStackName}.containers.${managementServerName}.traefik.serviceUrl
        else cloudManagementUrl;
      defaultText = lib.literalExpression ''
        if config.nps.stacks.${managementStackName}.enable
        then config.nps.stacks.${managementStackName}.containers.${managementServerName}.traefik.serviceUrl
        else "${cloudManagementUrl}"
      '';
      description = ''
        URL of the management service this peer registers with.
        Defaults to the `netbird-management` stack when it is enabled, otherwise to NetBird Cloud.
      '';
    };

    peerName = lib.mkOption {
      type = lib.types.str;
      default = name;
      description = ''
        Name this peer registers with.
        Becomes the container hostname, so it is how the device is shown in the management service.
      '';
    };

    enableRouting = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable IP forwarding inside the container so this peer can act as a
        routing peer and forward traffic from the overlay network to the host network.

        The routes themselves still have to be configured in the NetBird management service.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "docker.io/netbirdio/netbird:0.78.0";

      addCapabilities = [
        "NET_RAW"
        "NET_ADMIN"
        "SYS_ADMIN"
        "SYS_RESOURCE"
        "SYS_MODULE"
      ];
      devices = ["/dev/net/tun"];

      # Join Traefik network to for Traefiks NetworkAlias routes
      network = [config.nps.stacks.traefik.network.name];
      extraPodmanArgs =
        [
          # NetBird derives the peer name from the hostname of the machine.
          "--hostname=${cfg.peerName}"
        ]
        ++ lib.optionals cfg.enableRouting [
          "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
          "--sysctl=net.ipv4.ip_forward=1"
          "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
          "--sysctl=net.ipv6.conf.all.forwarding=1"
          "--sysctl=net.ipv6.conf.default.forwarding=1"
        ];

      extraEnv = {
        NB_MANAGEMENT_URL = cfg.managementUrl;
        NB_SETUP_KEY.fromFile = cfg.setupKeyFile;
      };

      volumeMap.data = "${storage}/data:/var/lib/netbird";
    };
  };
}
