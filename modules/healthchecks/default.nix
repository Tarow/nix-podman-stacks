{
  config,
  lib,
  ...
}: let
  name = "healthchecks";

  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};

  category = "Monitoring";
  description = "Job Monitoring";
  displayName = "Healthchecks";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    secretKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the secret key.

        See <https://healthchecks.io/docs/self_hosted_configuration/#SECRET_KEY>
      '';
    };
    superUserEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email address of the superuser account";
    };
    superUserPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the superuser password";
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers = {
      ${name} = {
        # renovate: versioning=regex:^v(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-ls(?<build>.+)$
        image = "ghcr.io/linuxserver/healthchecks:v3.11.2-ls314";
        volumes = ["${storage}/config:/config"];
        environment = {
          PUID = config.nps.defaultUid;
          PGID = config.nps.defaultGid;
          SITE_ROOT = config.services.podman.containers.${name}.traefik.serviceUrl;
          SITE_NAME = "Healthchecks";
          REGISTRATION_OPEN = "False";
          INTEGRATIONS_ALLOW_PRIVATE_IPS = "True";
          APPRISE_ENABLED = "True";
          DEBUG = "False";
        };
        extraEnv = {
          SECRET_KEY.fromFile = cfg.secretKeyFile;
          SUPERUSER_EMAIL = cfg.superUserEmail;
          SUPERUSER_PASSWORD.fromFile = cfg.superUserPasswordFile;
        };

        port = 8000;

        stack = name;
        traefik.name = name;
        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "healthchecks";
            widget.type = "healthchecks";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:healthchecks";
        };
      };
    };
  };
}
