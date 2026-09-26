{config, ...}: {
  nps = {
    hostIP4Address = "192.168.178.2";
    hostUid = 1000;
    storageBaseDir = "${config.home.homeDirectory}/stacks";
    externalStorageBaseDir = "/mnt/hdd";

    stacks = {
      authelia = {
        enable = true;
        jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
        sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
        storageEncryptionKeyFile = config.sops.secrets."authelia/encryption_key".path;
        oidc = {
          enable = true;
          hmacSecretFile = config.sops.secrets."authelia/oidc_hmac_secret".path;
          jwksRsaKeyFile = config.sops.secrets."authelia/oidc_rsa_pk".path;
        };
      };

      blocky = {
        enable = true;
        enableGrafanaDashboard = true;
        enablePrometheusExport = true;
        containers.blocky = {
          # Clicking the Blocky icon redirects to the Grafana dashboard
          dashboard.url = "${config.nps.containers.grafana.traefik.serviceUrl}/d/blocky";
        };
      };

      crowdsec = {
        enable = true;
      };

      docker-socket-proxy.enable = true;

      homepage.enable = true;

      immich = {
        enable = true;
        oidc = {
          enable = true;
          clientSecretFile = config.sops.secrets."immich/authelia_client_secret".path;
          clientSecretHash = "$pbkdf2-sha512$310000$CmFYHZTQ0aMd9P/RaFJjrw$7Mht0oY97PDzdLP6GbEKB1dZ1ZQeL66TjrfhjyV0sWOtGKDxkyTcUFfIEh/bzPKM2Bs4.BCmZZWkYiKZ2E0T5Q";
        };
        db.passwordFile = config.sops.secrets."immich/db_password".path;
      };

      lldap = {
        enable = true;
        baseDn = "DC=example,DC=com";
        jwtSecretFile = config.sops.secrets."lldap/jwt_secret".path;
        keySeedFile = config.sops.secrets."lldap/key_seed".path;
        adminPasswordFile = config.sops.secrets."lldap/admin_password".path;
        bootstrap = {
          cleanUp = true;
          users = {
            john = {
              email = "john@example.com";
              displayName = "John";
              password_file = config.sops.secrets."lldap/john_password".path;
              groups = with config.nps.stacks; [
                immich.oidc.adminGroup
                paperless.oidc.userGroup
              ];
            };
          };
        };
      };

      monitoring.enable = true;

      paperless = {
        enable = true;
        adminProvisioning = {
          username = "admin";
          email = "admin@example.com";
          passwordFile = config.sops.secrets."paperless/admin_password".path;
        };
        oidc = {
          enable = true;
          clientSecretFile = config.sops.secrets."paperless/authelia_client_secret".path;
          clientSecretHash = "$pbkdf2-sha512$310000$wUGniL1V/2bHarMRgE4GQQ$NeJhO.8afkZ7aYJQ5l9f5FfDwFp8dE8PWevkUYdvxP69zieO1kdEIX4xe2UCQvLsAd7pWmwwQgyypbkXQya7FQ";
        };
        secretKeyFile = config.sops.secrets."paperless/secret_key".path;
        db = {
          passwordFile = config.sops.secrets."paperless/db_password".path;
        };
      };

      traefik = {
        enable = true;
        domain = "example.com";
        extraEnv.CF_DNS_API_TOKEN.fromFile = config.sops.secrets."traefik/cf_api_token".path;
        geoblock.allowedCountries = ["DE"];
        enablePrometheusExport = true;
        enableGrafanaMetricsDashboard = true;
        enableGrafanaAccessLogDashboard = true;
        crowdsec.middleware.bouncerKeyFile = config.sops.secrets."traefik/crowdsec_bouncer_key".path;
      };
    };
  };
}
