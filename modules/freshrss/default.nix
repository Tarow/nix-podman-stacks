{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "freshrss";
  storage = "${config.nps.storageBaseDir}/${name}";
  cfg = config.nps.stacks.${name};
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the env file containing admin user secrets. The file should contain the variables
        'ADMIN_USERNAME', 'ADMIN_EMAIL', 'ADMIN_PASSWORD' and 'ADMIN_API_PASSWORD'.
        If the file is not set, automatic user creation will not be triggered. This only effects the first run.
        For details see https://github.com/FreshRSS/FreshRSS/tree/edge/Docker#environment-variables
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Fix for https://github.com/FreshRSS/FreshRSS/issues/7300
    # Override entrypoint so that secrets passed as env variables get interpolated
    nps.stacks.${name}.containers.${name} = let
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
      lib.mkIf (cfg.envFile != null) {
        entrypoint = "./Docker/patchedEntrypoint.sh";
        exec = "bash -c '([ -z \"\\$\\$CRON_MIN\" ] || cron) && . /etc/apache2/envvars && exec apache2 -D FOREGROUND'";
        volumes = ["${patchedEntryPoint}:/var/www/FreshRSS/Docker/patchedEntrypoint.sh"];
      };

    services.podman.containers.${name} = {
      image = "docker.io/freshrss/freshrss:1.27.0";
      volumes = [
        "${storage}/data:/var/www/FreshRSS/data"
        "${storage}/extensions:/var/www/FreshRSS/extensions"
      ];

      environment =
        {
          CRON_MIN = "3,33";
          TRUSTED_PROXY = config.nps.stacks.traefik.network.subnet;
        }
        // lib.optionalAttrs (cfg.envFile != null) {
          FRESHRSS_INSTALL = "'${lib.concatStringsSep " " [
            "--api-enabled"
            "--base-url ${cfg.containers.${name}.traefik.serviceDomain}"
            "--default-user \\$\\$\{ADMIN_USERNAME\}"
            "--language en"
          ]}'";

          FRESHRSS_USER = "'${lib.concatStringsSep " " [
            "--api-password \\$\\$\{ADMIN_API_PASSWORD\}"
            "--email \\$\\$\{ADMIN_EMAIL\}"
            "--language en"
            "--password \\$\\$\{ADMIN_PASSWORD\}"
            "--user \\$\\$\{ADMIN_USERNAME\}"
          ]}'";
        };
      environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

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
