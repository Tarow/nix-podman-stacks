{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "freshrss";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in
{
  imports = import ../mkAliases.nix config lib name [ name ];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    adminProvisioning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to automatically create an admin user on the first run.
          If set to false, you will be prompted to create an admin user when visiting the FreshRSS web interface for the first time.
          This only affects the first run of the container.
        '';
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username for the admin user";
      };
      adminEmail = lib.mkOption {
        type = lib.types.str;
        description = "Email address for the admin user ";
      };
      adminPasswordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin user password";
      };
      adminApiPasswordFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "Path to a file containing the admin API password";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Fix for https://github.com/FreshRSS/FreshRSS/issues/7300
    # Override entrypoint so that secrets passed as env variables get interpolated
    nps.stacks.${name}.containers.${name} =
      let
        patchedEntryPoint = pkgs.writeTextFile {
          name = "entrypoint.sh";
          executable = true;
          text = ''
            #!/bin/sh
            export FRESHRSS_USER="$(eval echo "$FRESHRSS_USER")"
            export FRESHRSS_INSTALL="$(eval echo "$FRESHRSS_INSTALL")"
            exec ./Docker/entrypoint.sh "$@"
          '';
        };
      in
      lib.mkIf (cfg.adminProvisioning.enable) {
        entrypoint = "./Docker/patchedEntrypoint.sh";
        exec = "bash -c '([ -z \"\\$\\$CRON_MIN\" ] || cron) && . /etc/apache2/envvars && exec apache2 -D FOREGROUND'";
        volumes = [ "${patchedEntryPoint}:/var/www/FreshRSS/Docker/patchedEntrypoint.sh" ];
      };

    services.podman.containers.${name} = {
      image = "docker.io/freshrss/freshrss:1.27.0";
      volumes = [
        "${storage}/data:/var/www/FreshRSS/data"
        "${storage}/extensions:/var/www/FreshRSS/extensions"
      ];

      extraEnv = {
        CRON_MIN = "3,33";
        TRUSTED_PROXY = config.nps.stacks.traefik.network.subnet;
      }
      // lib.optionalAttrs (cfg.adminProvisioning.enable) {
        ADMIN_USERNAME = cfg.adminProvisioning.username;
        ADMIN_EMAIL = cfg.adminProvisioning.adminEmail;
        ADMIN_PASSWORD.fromFile = cfg.adminProvisioning.adminPasswordFile;
        ADMIN_API_PASSWORD.fromFile = cfg.adminProvisioning.adminApiPasswordFile;

        FRESHRSS_INSTALL = "'${
          lib.concatStringsSep " " [
            "--api-enabled"
            "--base-url ${cfg.containers.${name}.traefik.serviceDomain}"
            "--default-user \\$\\$\{ADMIN_USERNAME\}"
            "--language en"
          ]
        }'";

        FRESHRSS_USER = "'${
          lib.concatStringsSep " " [
            "--api-password \\$\\$\{ADMIN_API_PASSWORD\}"
            "--email \\$\\$\{ADMIN_EMAIL\}"
            "--language en"
            "--password \\$\\$\{ADMIN_PASSWORD\}"
            "--user \\$\\$\{ADMIN_USERNAME\}"
          ]
        }'";
      };

      port = 80;
      traefik.name = name;
      homepage = {
        category = "General";
        name = "FreshRSS";
        settings = {
          description = "Feeds Aggregator";
          icon = "freshrss";
        };
      };
    };
  };
}
