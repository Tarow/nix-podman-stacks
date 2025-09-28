{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "lldap";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "Network & Administration";
  description = "Light LDAP Implementation";
  displayName = "LLDAP";

  toml = pkgs.formats.toml {};
  json = pkgs.formats.json {};

  customAttrsType = lib.types.oneOf [
    lib.types.str
    lib.types.int
    lib.types.bool
  ];
  schemaType = lib.types.attrsOf (
    lib.types.submodule (
      {name, ...}: {
        options = {
          name = lib.mkOption {
            type = lib.types.strMatching "^[a-zA-Z0-9-]+$";
            description = "Name of field, case insensitve - you should use lowercase";
            default = name;
            defaultText = lib.literalExpression ''<name>'';
          };
          attributeType = lib.mkOption {
            type = lib.types.enum [
              "STRING"
              "INTEGER"
              "JPGEG"
              "DATE_TIME"
            ];
            description = "Type of the attribute";
          };
          isEditable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the attribute is editable by users";
          };
          isList = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the attribute can have multiple values";
          };
          isVisible = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether the attribute is visible by users";
          };
        };
      }
    )
  );

  mkUserPasswordSecret = userId: srcPath: let
    dstPath = "/run/secrets/users/${userId}_pw";
  in
    if srcPath == null
    then {
      volume = [];
      dstPath = null;
    }
    else {
      volume = ["${srcPath}:${dstPath}"];
      dstPath = dstPath;
    };

  userPasswordFiles =
    cfg.bootstrap.users
    |> lib.attrValues
    |> map (u: lib.nameValuePair u.id (mkUserPasswordSecret u.id (u.password_file or null)))
    |> lib.listToAttrs
    |> lib.filterAttrs (_: v: v.dstPath != null);

  userConfigsDir = "/bootstrap/user-configs";
  groupConfigsDir = "/bootstrap/group-configs";
  userSchemasDir = "/bootstrap/user-schemas";
  groupSchemasDir = "/bootstrap/group-schemas";

  finalUserVolumes =
    cfg.bootstrap.users
    |> lib.attrValues
    |> map (
      u:
        lib.filterAttrs (_: v: v != null) (
          u // {password_file = userPasswordFiles.${u.id}.dstPath or null;}
        )
    )
    |> map (u: "${json.generate "${u.id}.json" u}:${userConfigsDir}/${u.id}.json");

  finalGroupVolumes =
    cfg.bootstrap.groups
    |> lib.attrValues
    |> map (g: "${json.generate "${g.name}.json" g}:${groupConfigsDir}/${g.name}.json");

  finalUserSchemaVolumes = "${json.generate "user_schemas.json" (lib.attrValues cfg.bootstrap.userSchemas)}:${userSchemasDir}/user_schemas.json";
  finalGroupSchemaVolumes = "${json.generate "group_schemas.json" (lib.attrValues cfg.bootstrap.groupSchemas)}:${groupSchemasDir}/group_schemas.json";

  bootstrapWrapper = pkgs.writeTextFile {
    name = "bootstrap_wrapper.sh";
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export LLDAP_ADMIN_USERNAME="${cfg.adminUsername}"
      export LLDAP_ADMIN_PASSWORD="$(cat ${
        cfg.containers.${name}.fileEnvMount.LLDAP_LDAP_USER_PASS_FILE.destPath
      })"
      export USER_CONFIGS_DIR="${userConfigsDir}"
      export GROUP_CONFIGS_DIR="${groupConfigsDir}"
      export USER_SCHEMAS_DIR="${userSchemasDir}"
      export GROUP_SCHEMAS_DIR="${groupSchemasDir}"
      export DO_CLEANUP="${
        if cfg.bootstrap.cleanUp
        then "true"
        else "false"
      }"
      exec /app/bootstrap.sh
    '';
  };
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    settings = lib.mkOption {
      type = lib.types.nullOr toml.type;
      apply = toml.generate "lldap_config.toml";
      description = ''
        Additional lldap configuration.
        If provided, will be mounted as `lldap_config.toml`;

        See <https://github.com/lldap/lldap/blob/main/lldap_config.docker_template.toml>
      '';
    };
    adminUsername = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = ''
        Admin username for LDAP as well as the web interface.
      '';
    };
    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the file containing the admin password.
      '';
    };
    jwtSecretFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the JWT secret";
    };
    keySeedFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the key seed";
    };
    bootstrap = {
      cleanUp = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to delete groups and users not specified in the config, also remove users from groups that they do not belong to
        '';
      };
      users = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            {name, ...}: {
              freeformType = customAttrsType;
              options = {
                id = lib.mkOption {
                  type = lib.types.str;
                  description = "ID of the user. Defaults to the name of the attribute.";
                  default = name;
                  defaultText = lib.literalExpression ''<name>'';
                };
                email = lib.mkOption {
                  type = lib.types.str;
                  description = "E-Mail of the user";
                };
                password_file = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Path to the file containing the user password";
                };
                displayName = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Display name of the user";
                };
                firstName = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "First name of the user";
                };
                lastName = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Last name of the user";
                };
                avatar_url = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Must be a valid URL to jpeg file. (ignored if `gravatar_avatar` specified)";
                };
                gravatar_avatar = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "the script will try to get an avatar from [gravatar](https://gravatar.com/) by previously specified email";
                };
                groups = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [];
                  description = "An array of groups the user will be a member of (all the groups must be specified in the `bootstrap.groups` option)";
                };
              };
            }
          )
        );
        default = [];
        description = ''
          LLDAP users that will be provisioned at startup.
          You can also specify custom attributes for the user, if they are defined in the `useSchemas` option.

          See <https://github.com/lldap/lldap/blob/main/example_configs/bootstrap/bootstrap.md#user-config-file-example>
        '';
      };
      groups = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            {name, ...}: {
              freeformType = customAttrsType;
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of the group. Defaults to the name of the attribute.";
                  default = name;
                  defaultText = lib.literalExpression ''<name>'';
                };
              };
            }
          )
        );
        default = {};
        description = ''
          Groups that will be created.
          Besides the name, you can also specify custom attributes for the group, if they are defined in the `groupSchemas` option.

          See <https://github.com/lldap/lldap/blob/main/example_configs/bootstrap/bootstrap.md#group-config-file-example>
        '';
      };
      userSchemas = lib.mkOption {
        type = schemaType;
        default = {};
        description = ''
          User schema. Can be used to create custom user attributes.
        '';
      };
      groupSchemas = lib.mkOption {
        type = schemaType;
        default = {};
        description = ''
          Group schemas. Can be used to create custom group attributes.
        '';
      };
    };
    baseDn = lib.mkOption {
      type = lib.types.str;
      default = "DC=example,DC=com";
      description = ''
        The starting point in the LDAP directory tree from which searches begin.
      '';
      example = "DC=mydomain,DC=net";
    };
    address = lib.mkOption {
      type = lib.types.str;
      default = "ldap://${name}:3890";
      readOnly = true;
      visible = false;
    };
    adminGroup = lib.mkOption {
      type = lib.types.str;
      default = "lldap_admin";
      readOnly = true;
      description = "Name of the built-in admin group";
      visible = false;
    };
    readOnlyGroup = lib.mkOption {
      type = lib.types.str;
      default = "lldap_strict_readonly";
      readOnly = true;
      description = "Name of the built-in read-only group";
      visible = false;
    };
    passwordManagerGroup = lib.mkOption {
      type = lib.types.str;
      default = "lldap_password_manager";
      readOnly = true;
      description = "Name of the built-in password manager group";
      visible = false;
    };
  };

  config = lib.mkIf cfg.enable {
    nps.stacks.${name} = {
      settings = {
        ldap_base_dn = cfg.baseDn;
        ldap_user_dn = cfg.adminUsername;
        database_url = "sqlite:///db/users.db?mode=rwc";
      };
    };

    services.podman.containers.${name} = {
      # Always use rootless images here with root-user, because otherwise chown on the read-only
      # lldap_config.toml will be attemped which fails

      # renovate: versioning=loose
      image = "ghcr.io/lldap/lldap:2025-09-28-alpine-rootless";
      user = config.nps.defaultUid;
      volumes =
        [
          "${storage}/db:/db"
          "${cfg.settings}:/data/lldap_config.toml"
        ]
        ++ (builtins.concatLists (map (s: s.volume) (lib.attrValues userPasswordFiles)))
        ++ lib.flatten [
          finalUserVolumes
          finalGroupVolumes
          finalUserSchemaVolumes
          finalGroupSchemaVolumes
          "${bootstrapWrapper}:/app/bootstrap_wrapper.sh"
        ];

      extraConfig.Service.ExecStartPost = ["${lib.getExe config.nps.package} exec ${name} /app/bootstrap_wrapper.sh"];

      environment = {
        LLDAP_KEY_FILE = "";
        FORCE_LDAP_USER_PASS_RESET = lib.mkDefault "always";
      };
      fileEnvMount = {
        LLDAP_JWT_SECRET_FILE = cfg.jwtSecretFile;
        LLDAP_KEY_SEED_FILE = cfg.keySeedFile;
        LLDAP_LDAP_USER_PASS_FILE = cfg.adminPasswordFile;
      };

      port = 17170;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "lldap-dark";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "auto-invert di:lldap";
      };
    };
  };
}
