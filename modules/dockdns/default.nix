{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "dockdns";
  cfg = config.nps.stacks.${name};
  yaml = pkgs.formats.yaml {};

  category = "Network & Administration";
  displayName = "DockDNS";
  description = "Label-based DNS Client";
in {
  imports =
    [
      ./extension.nix
      (import ../docker-socket-proxy/mkSocketProxyOptionModule.nix {stack = name;})
    ]
    ++ import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable =
      lib.mkEnableOption name
      // {
        description = ''
          Whether to enable DockDNS. This will run a Cloudflare DNS client that updates DNS records based on Docker labels.
          The module contains an extension that will automatically create DNS records for services with the `public` Traefik middleware,
          so they are accessible from the internet. Optionally it will also automatically delete DNS records for services, that are no longer exposed (e.g. `private` middleware)
        '';
      };
    settings = lib.mkOption {
      type = yaml.type;
      description = ''
        Settings for DockDNS.
        For details, refer to the [DockDNS documentation](https://github.com/Tarow/dockdns?tab=readme-ov-file#configuration)
        The module will provide a default configuration, that updates DNS records every 10 minutes.
        DockDNS labels will be automatically added to services with the `public` Traefik middleware.
      '';
      apply = yaml.generate "dockdns_config.yaml";
    };
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.
        Variables can be either set directly or sourced from a file (e.g. for secrets).

        See <https://github.com/crowdsecurity/crowdsec/blob/master/docker/README.md#environment-variables>
      '';
      example = {
        SOME_SECRET = {
          fromFile = "/run/secrets/secret_name";
        };
        FOO = "bar";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name}.settings = lib.mkMerge [
      # Apply all leaf-attributes with default priority.
      # Allows for easy overriding of leaf-attributes
      (import ./config.nix |> lib.mapAttrsRecursive (_: lib.mkDefault))

      (lib.mkIf config.nps.stacks.traefik.enable {
        zones = [
          {
            name = config.nps.stacks.traefik.domain;
            provider = "cloudflare";
          }
        ];
      })
    ];

    services.podman.containers.${name} = {
      image = "ghcr.io/tarow/dockdns:v0.8.0";
      volumes = [
        "${cfg.settings}:/app/config.yaml"
      ];

      extraEnv =
        {
          DOCKER_HOST = lib.mkIf (cfg.useSocketProxy) config.nps.stacks.docker-socket-proxy.address;
        }
        // cfg.extraEnv;

      port = 8080;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "azure-dns";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "di:azure-dns";
      };
    };
  };
}
