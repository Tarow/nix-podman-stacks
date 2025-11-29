{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "authelia";
  redisName = "${name}-redis";
  cfg = config.nps.stacks.${name};

  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Network & Administration";
  displayName = "Authelia";
  description = "Authentication & Authorization Server";

  yaml = pkgs.formats.yaml {};

  # Write this file manually, otherwise there will be single quotes around the key, breaking the file after templating
  writeOidcJwksConfigFile = oidcIssuerPrivateKeyFile:
    pkgs.writeText "oidc-jwks.yaml" ''
      identity_providers:
        oidc:
          jwks:
            - key: {{ secret "${oidcIssuerPrivateKeyFile}" | mindent 10 "|" | msquote }}
    '';

  oidcEnabled = cfg.oidc.enable && (lib.length (lib.attrValues cfg.oidc.clients) > 0);
  container = cfg.containers.${name};
  lldap = config.nps.stacks.lldap;
in {
  imports = [./extension.nix] ++ import ../mkAliases.nix config lib name [name redisName];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the JWT secret.
        See <https://www.authelia.com/configuration/identity-validation/reset-password/#jwt_secret>
      '';
    };
    sessionSecretFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the session secret.
        See <https://www.authelia.com/configuration/session/introduction/#secret>
      '';
    };
    storageEncryptionKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the storage encryption key.
        See <https://www.authelia.com/configuration/storage/introduction/#encryption_key>
      '';
    };
    defaultAllowPolicy = lib.mkOption {
      type = lib.types.enum ["one_factor" "two_factor"];
      default = "one_factor";
      description = ''
        Default policy to apply for allowed access. Will be used as a default for Access Control Rules as well as OIDC Authorization Policies if no rules apply.

        See
        - <https://www.authelia.com/configuration/identity-providers/openid-connect/clients/#authorization_policy>
        - <https://www.authelia.com/configuration/security/access-control/#rules>
      '';
    };
    oidc = {
      enable = lib.mkEnableOption "OIDC Support";
      hmacSecretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing the HMAC secret.
          See <https://www.authelia.com/configuration/identity-providers/openid-connect/provider/#hmac_secret>
        '';
      };
      jwksRsaKeyFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing the JWKS RSA (RS256) private key.

          For example, a keypair can be generated and printed out like this:
          ```sh
          podman run --rm authelia/authelia sh -c "authelia crypto certificate rsa generate --common-name authelia.example.com && cat public.crt && cat private.pem"
          ```

          See <https://www.authelia.com/configuration/identity-providers/openid-connect/provider/#key>
        '';
      };
      clients = lib.mkOption {
        description = ''
          OIDC client configuration.
          See <https://www.authelia.com/configuration/identity-providers/openid-connect/clients/>
        '';
        default = {};
        type = lib.types.attrsOf (
          lib.types.submodule (
            {name, ...}: {
              freeformType = yaml.type;
              options = {
                client_id = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                };
              };
            }
          )
        );
      };
      defaultConsentDuration = lib.mkOption {
        type = lib.types.str;
        default = "1 month";
        description = ''
          Default period of how long a users choice to remember the pre-configured consent lasts.
          Only has an effect for OIDC clients using the consent_mode `pre-configured` or `auto`.

          See
          - <https://www.authelia.com/configuration/identity-providers/openid-connect/clients/#pre_configured_consent_duration>
        '';
      };
    };
    sessionProvider = lib.mkOption {
      type = lib.types.enum ["memory" "redis"];
      default = "memory";
      description = "''
        Session provider to use.

        See <https://www.authelia.com/configuration/session/introduction/>
      ''";
    };
    settings = lib.mkOption {
      type = yaml.type;
      apply = yaml.generate "configuration.yml";
      description = ''
        Additional Authelia settings. Will be provided in the `configuration.yml`.
      '';
    };

    ldap = {
      username = lib.mkOption {
        type = lib.types.str;
        default = config.nps.stacks.lldap.adminUsername;
        defaultText = lib.literalExpression ''config.nps.stacks.lldap.adminUsername'';
        description = ''
          The username that will be used when binding to the LDAP backend.
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.path;
        default = config.nps.stacks.lldap.adminPasswordFile;
        defaultText = lib.literalExpression ''config.nps.stacks.lldap.adminPasswordFile'';
        description = ''
          The password for the LDAP user that is used when connecting to the LDAP backend.
        '';
      };
    };

    enableTraefikMiddleware = lib.mkOption {
      type = lib.types.bool;
      default = config.nps.stacks.traefik.enable;
      defaultText = lib.literalExpression ''config.nps.stacks.traefik.enable'';
      description = ''
        Wheter to register an `authelia` middleware for Traefik.
        The middleware will utilize the ForwardAuth Authz implementation.

        See <https://www.authelia.com/integration/proxies/traefik/#implementation>
      '';
    };
    crowdsec = {
      enableLogCollection = lib.mkOption {
        type = lib.types.bool;
        default = config.nps.stacks.crowdsec.enable;
        defaultText = lib.literalExpression ''config.nps.stacks.crowdsec.enable'';
        description = ''
          Whether the container logs should be collected by CrowdSec.
          Enabling this will configure the acquis settings for CrowdSec.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.nps.stacks.lldap.enable;
        message = "Authelia requires the `lldap` stack to be enabled";
      }
    ];

    nps.stacks.crowdsec = lib.mkIf cfg.crowdsec.enableLogCollection {
      collections = "LePresidente/authelia";
      acquisSettings.authelia = {
        source = "docker";
        container_name = [name];
        labels = {
          type = "authelia";
        };
      };
    };

    nps.stacks.${name}.settings = {
      identity_providers = lib.mkIf oidcEnabled {
        oidc = {
          jwks = [
            {
              algorithm = "RS256";
              use = "sig";
              # Key will written in extra config file to avoid templating issues
            }
          ];
          lifespans = {
            access_token = "1h";
            authorize_code = "1m";
            id_token = "1h";
            refresh_token = "90m";
          };
          clients = lib.attrValues cfg.oidc.clients;
        };
      };

      authentication_backend = {
        ldap = {
          address = lldap.address;
          implementation = "lldap";
          base_dn = lldap.baseDn;
          user = "CN=${cfg.ldap.username},OU=people," + lldap.baseDn;
        };

        refresh_interval = "1m";

        # Disable by default as it can be done through LLDAP
        password_reset.disable = lib.mkDefault true;
        password_change.disable = lib.mkDefault true;
      };
      access_control.default_policy = config.nps.stacks.${name}.defaultAllowPolicy;
      notifier.filesystem.filename = "/notifier/notification.txt";
      session =
        {
          name = "authelia_session";
          same_site = "lax";
          inactivity = "5m";
          expiration = "1h";
          remember_me = "1M";
          cookies = [
            {
              domain = config.nps.stacks.traefik.domain;
              authelia_url = container.traefik.serviceUrl;
              name = "authelia_session";
            }
          ];
        }
        // lib.optionalAttrs (cfg.sessionProvider == "redis") {
          redis.host = redisName;
        };

      server = lib.mkIf cfg.enableTraefikMiddleware {
        endpoints.authz.forward-auth.implementation = "ForwardAuth";
      };
      webauthn.enable_passkey_login = true;
      theme = "auto";
    };

    nps.stacks.traefik = lib.mkIf cfg.enableTraefikMiddleware {
      containers.traefik.wantsContainer = [name];
      dynamicConfig.http.middlewares.authelia.forwardAuth = {
        address = "http://authelia:9091/api/authz/forward-auth?authelia_url=https%3A%2F%2F${
          cfg.containers.${name}.traefik.serviceHost
        }%2F";
        trustForwardHeader = true;
        authResponseHeaders = "Remote-User,Remote-Groups,Remote-Email,Remote-Name";
      };
    };

    services.podman.containers = {
      ${name} = {
        image = "ghcr.io/authelia/authelia:4.39.15";
        environment =
          {
            AUTHELIA_STORAGE_LOCAL_PATH = "/data/db.sqlite3";
          }
          // lib.optionalAttrs oidcEnabled {
            X_AUTHELIA_CONFIG_FILTERS = "template";
            X_AUTHELIA_CONFIG = "/config/configuration.yml,/config/jwks_key_config.yml";
          };

        fileEnvMount =
          {
            AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = cfg.jwtSecretFile;
            AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = cfg.storageEncryptionKeyFile;
            AUTHELIA_SESSION_SECRET_FILE = cfg.sessionSecretFile;
            AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = cfg.ldap.passwordFile;
          }
          // lib.optionalAttrs oidcEnabled {
            IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = cfg.oidc.hmacSecretFile;
          };

        volumes =
          [
            "${storage}/db:/data"
            "${storage}/notifier:/notifier"
            "${cfg.settings}:/config/configuration.yml"
          ]
          ++ lib.optionals oidcEnabled [
            "${cfg.oidc.jwksRsaKeyFile}:/secrets/oidc/jwks/rsa.key"
            "${writeOidcJwksConfigFile "/secrets/oidc/jwks/rsa.key"}:/config/jwks_key_config.yml"
          ];

        wantsContainer = lib.optional (cfg.sessionProvider == "redis") redisName;
        stack = name;
        port = 9091;
        traefik.name = name;

        homepage = {
          inherit category;
          name = displayName;
          settings = {
            inherit description;
            icon = "authelia";
          };
        };
        glance = {
          inherit category description;
          name = displayName;
          id = name;
          icon = "di:authelia";
        };
      };

      ${redisName} = lib.mkIf (cfg.sessionProvider == "redis") {
        image = "docker.io/redis:8.2.1";
        stack = name;
        volumes = ["${storage}/redis:/data"];

        extraConfig.Container = {
          Notify = "healthy";
          HealthCmd = "redis-cli ping";
          HealthInterval = "10s";
          HealthTimeout = "10s";
          HealthRetries = 5;
          HealthStartPeriod = "10s";
        };
        glance = {
          parent = name;
          name = "Redis";
          icon = "di:redis";
          inherit category;
        };
      };
    };
  };
}
