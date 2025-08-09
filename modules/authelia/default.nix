{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  name = "authelia";
  cfg = config.tarow.podman.stacks.${name};

  storage = "${config.tarow.podman.storageBaseDir}/${name}";

  yaml = pkgs.formats.yaml {};

  # Write this file manually, otherwise there will be single quotes around the key, breaking the file after templating
  writeOidcJwksConfigFile = oidcIssuerPrivateKeyFile:
    pkgs.writeText "oidc-jwks.yaml" ''
      identity_providers:
        oidc:
          jwks:
            - key: {{ secret "${oidcIssuerPrivateKeyFile}" | mindent 10 "|" | msquote }}
    '';
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.tarow.podman.stacks.${name} = {
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
    env = lib.mkOption {
      type = (options.services.podman.containers.type.getSubOptions []).environment.type;
      default = {};
      description = "Additional environment variables passed to the Authelia container";
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the environment file containing addiotional variables.
        Can be used to pass secrets etc.
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
        default = [];
        type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
          freeformType = yaml.type;
          options = {
            client_id = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
          };
        }));
      };
    };
    settings = lib.mkOption {
      type = yaml.type;
      apply = yaml.generate "configuration.yml";
      description = ''
        Additional Authelia settings. Will be provided in the `configuration.yml`.
      '';
    };
    authenticationBackend = {
      type = lib.mkOption {
        type = lib.types.enum ["file" "ldap"];
        default =
          if config.tarow.podman.stacks.lldap.enable
          then "ldap"
          else "file";
        defaultText = lib.literalExpression ''if config.tarow.podman.stacks.lldap.enable then "ldap" else "file"'';
        description = ''
          The authentication backend that will be used.
          If set to `ldap` the option `ldapPasswordFile` has to be set.
          If set to `file` either the `users` or the `usersFile` option has to be set.
        '';
      };
      ldapPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containing the LDAP password for the user defined in `config.tarow.podman.stacks.lldap.bindDn`.
        '';
      };
      users = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
          freeformType = yaml.type;
          options = {
            disabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "The disabled status for the user";
            };
            displayname = lib.mkOption {
              type = lib.types.str;
              default = name;
              defaultText = "key of the attribute set";
              description = "The display name for the user";
            };
            password = lib.mkOption {
              type = lib.types.str;
              description = "The hashed password for the user";
            };
            email = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "The email for the user";
            };
            groups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "The groups list for the user";
            };
          };
        }));
        default = {};
        description = ''
          User configuration. Besides the defined options, any value can be defined here.
          See <https://www.authelia.com/reference/guides/passwords/#yaml-format>

          Note: Configuring the users through this option file result in a read-only file being mounted into the container.
          Because the file isn't writable, users won't be able to reset or change their passwords themselves.

          If you want to mount a writable file, use the `usersFile` option instead.
        '';
      };
      usersFile = lib.mkOption {
        type = lib.types.nullOr (lib.types.pathWith {
          inStore = false;
          absolute = true;
        });
        default = null;
        description = ''
          Path to a file containing the user configuration.
          See <https://www.authelia.com/reference/guides/passwords/#yaml-format>

          If this option is defined, the `users` option will be ignored.
        '';
      };
    };
  };

  config = let
    oidcEnabled = cfg.oidc.enable && (lib.length (lib.attrValues cfg.oidc.clients) > 0);
    container = cfg.containers.${name};
    lldap = config.tarow.podman.stacks.lldap;

    finalUsersFile =
      if cfg.authenticationBackend.users != {}
      then yaml.generate "users.yml" {users = cfg.authenticationBackend.users;}
      else cfg.authenticationBackend.usersFile;
    usersReadOnly = cfg.authenticationBackend.usersFile != {};

    useLdap = cfg.authenticationBackend.type == "ldap";
  in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.authenticationBackend.type != "ldap" || config.tarow.podman.stacks.lldap.enable;
          message = "The option 'tarow.podman.stacks.${name}.authenticationBackend.type' is set to `ldap`, but the 'lldap' stack is not enabled.";
        }
        {
          assertion =
            cfg.authenticationBackend.type
            != "file"
            || ((cfg.authenticationBackend.users != {}) != (cfg.authenticationBackend.usersFile != null));
          message = ''
            Authelia: When `authenticationBackend.type` is set to "file", exactly one of `users` or `usersFile` has to be set.
          '';
        }
      ];

      tarow.podman.stacks.${name}.settings = {
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
          ldap = lib.mkIf useLdap {
            address = lldap.address;
            implementation = "lldap";
            base_dn = lldap.baseDn;
            user = lldap.bindDn;
          };
          file = lib.mkIf (!useLdap) {
            path = "/config/users.yml";
            watch = !usersReadOnly;
            password = {
              algorithm = "argon2";
              argon2.variant = "argon2id";
            };
          };

          # Disable password reset/change if users file is readonly (when mounted from Nix store)
          password_reset.disable = !useLdap && usersReadOnly;
          password_change.disable = !useLdap && usersReadOnly;
        };
        access_control.default_policy = "one_factor";
        notifier.filesystem.filename = "/notifier/notification.txt";
        session = {
          name = "authelia_session";
          same_site = "lax";
          inactivity = "5m";
          expiration = "1h";
          remember_me = "1M";
          cookies = [
            {
              domain = config.tarow.podman.stacks.traefik.domain;
              authelia_url = container.traefik.serviceDomain;
              name = "authelia_session";
            }
          ];
        };
      };

      services.podman.containers.${name} = {
        image = "ghcr.io/authelia/authelia:4.39.6";
        environment =
          {
            AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = "/secrets/JWT_SECRET";
            AUTHELIA_SESSION_SECRET_FILE = "/secrets/SESSION_SECRET";
            AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = "/secrets/STORAGE_ENCRYPTION_KEY";
            AUTHELIA_STORAGE_LOCAL_PATH = "/data/db.sqlite3";
          }
          // lib.optionalAttrs oidcEnabled {
            IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "/secrets/oidc/HMAC_SECRET";
            X_AUTHELIA_CONFIG_FILTERS = "template";
            X_AUTHELIA_CONFIG = "/config/configuration.yml,/config/jwks_key_config.yml";
          }
          // lib.optionalAttrs useLdap {
            AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "/secrets/ldap/PASSWORD";
          }
          // cfg.env;
        environmentFile = lib.optional (cfg.envFile != null) cfg.envFile;

        volumes =
          [
            "${storage}/db:/data"
            "${storage}/notifier:/notifier"
            "${cfg.settings}:/config/configuration.yml"
            "${cfg.jwtSecretFile}:/secrets/JWT_SECRET"
            "${cfg.sessionSecretFile}:/secrets/SESSION_SECRET"
            "${cfg.storageEncryptionKeyFile}:/secrets/STORAGE_ENCRYPTION_KEY"
          ]
          ++ lib.optionals oidcEnabled [
            "${cfg.oidc.hmacSecretFile}:/secrets/oidc/HMAC_SECRET"
            "${cfg.oidc.jwksRsaKeyFile}:/secrets/oidc/jwks/rsa.key"
            "${writeOidcJwksConfigFile "/secrets/oidc/jwks/rsa.key"}:/config/jwks_key_config.yml"
          ]
          ++ lib.optional useLdap "${cfg.authenticationBackend.ldapPasswordFile}:/secrets/ldap/PASSWORD"
          ++ lib.optional (!useLdap) "${finalUsersFile}:/config/users.yml";

        port = 9091;
        traefik.name = name;
        homepage = {
          category = "Network & Administration";
          name = "Authelia";
          settings = {
            description = "Authentication & Authorization Server";
            icon = "authelia";
          };
        };
      };
    };
}
