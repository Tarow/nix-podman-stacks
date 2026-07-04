{
  pkgs,
  lib,
  config,
  ...
}: let
  globalConf = config;
  mkSocketName = {
    name,
    port,
    prefix ? "podman-",
    suffix ? ".socket",
  }: "${prefix}${name}-${toString port |> lib.replaceStrings ["." ":"] ["_" "-"]}${suffix}";
in {
  # Extend the podman options in order to custom build custom abstraction
  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          name,
          config,
          ...
        }: {
          options = with lib; {
            dependsOn = mkOption {
              type = types.listOf types.str;
              default = [];
              description = ''
                List of systemd resources that this container depends on.
                This is a hard requirement and will setup systemd `Require` and `After` attributes.
                When specifying a dependency on another container, use the option `dependsOnContainer` instead.

                See
                - <https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Requires=>
                - <https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Before=>
              '';
            };

            dependsOnContainer = mkOption {
              type = types.listOf types.str;
              default = [];
              apply = map (d: "podman-${d}.service");
              description = ''
                List of containers that this container depends on.
                Similar to `dependsOn`, but will automatically apply correct pre- and suffix for
                the generated systemd services.
              '';
            };

            wants = mkOption {
              type = types.listOf types.str;
              default = [];
              description = ''
                List of systemd resources that this container depends on.
                Compared to `dependsOn`, this is a softer requirement and will setup systemd `Wants` and `After` attributes.
                When specifying a dependency on another container, use the option `wantsContainer` instead.

                See
                - <https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Wants=>
                - <https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Before=>
              '';
            };

            wantsContainer = mkOption {
              type = types.listOf types.str;
              default = [];
              apply = map (d: "podman-${d}.service");
              description = ''
                List of containers that this container depends on.
                Similar to `wants`, but will automatically apply correct pre- and suffix for
                the generated systemd services.
              '';
            };

            # Extend upstream option. Filter out null values, so env variables can be unset when overwritten
            environment = lib.mkOption {
              apply = lib.filterAttrs (k: v: v != null);
            };

            extraEnv = lib.mkOption {
              type = (import ./types.nix lib).extraEnv;
              default = {};
              example = {
                # Load environment variables from a file
                ENCRYPTION_KEY = "literal-value";
                DB_PASSWORD = {
                  fromFile = "/some/path/secrets/db-password";
                };
                DB_URL = {
                  fromTemplate = ''postgresql://user:{{ file.Read `/run/secrets/db_password` }}@localhost:5432/mydb'';
                };
                API_KEY = {
                  fromFile = "/home/user/api-key";
                };
              };
              description = ''
                Convinience wrapper option for passing environment variables to the container.
                The values of the environment variables can either be a primitive value or a path to a file.

                In case of passing a path (using the `fromFile` attribure), the file will be read and the content will be set as the value of the environment variable.
                Useful for containers that don't support passing environment variables using the "_FILE" pattern.
              '';
            };

            volumeMap = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = {};
              example = {
                db = "/host/foo/db:/db";
                config = "/host/bar/config:/config";
              };
              description = ''
                Attribute set of named volume mappings.
                This is just a wrapper of the `volumes` option, that allows defining volume mappings using an attrset.

                The stack modules will use the `volumeMap` to set volume mappings for the container. This allows overriding specific
                volume mappings without having to redefine the entire `volumes` list.
              '';
            };

            fileEnvMount = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.oneOf [
                  lib.types.path
                  (lib.types.submodule {
                    options = {
                      sourcePath = mkOption {
                        type = lib.types.str;
                        description = "Source path on host";
                      };
                      destPath = mkOption {
                        type = lib.types.str;
                      };
                    };
                  })
                ]
              );
              apply = lib.mapAttrs (
                name: value:
                  if builtins.isAttrs value
                  then value
                  else {
                    sourcePath = value;
                    destPath = "/run/secrets/${name}";
                  }
              );
              default = {};
              example = {
                # Short form: just give the source path, destPath is inferred
                DB_PASSWORD_FILE = "/run/secrets/db-password.txt";

                # Long form: explicitly set sourcePath and destPath
                API_KEY_FILE = {
                  sourcePath = "/secrets/api-key.txt";
                  destPath = "/app/config/api-key.txt";
                };
              };
              description = ''
                Convenience wrapper option, that simplifies passing `_FILE` based environment variables.
                For each attribute in the attrset, a volume mapping from `sourcePath` to `destPath` will be added,
                and an environment variable will be set to the `destPath`.

                Example:
                ```nix
                API_KEY_FILE = {
                  srcPath = "/host/api-key.txt";
                  dstPath = "/container/api-key.txt";
                };
                ```
                will add a volume to the container, e.g.:
                ```nix
                volumes = [''${sourcePath}:''${destPath}];
                ```
                and also add an environment variable:
                ```nix
                env.API_KEY_FILE = destPath;
                ```

                You can also provide a simple path, which will be treated as the `sourcePath`:
                ```nix
                DB_PASSWORD_FILE = ./secrets/db-password.txt;
                ```
                The `destPath` will be inferred.
              '';
            };

            templateMount = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    templatePath = lib.mkOption {
                      type = lib.types.path;
                      description = "Path to the template. The file will be templated with `gomplate` before being mounted.";
                    };
                    destPath = lib.mkOption {
                      type = lib.types.path;
                      description = "Destination path of the templated file within the container";
                    };
                    chown = lib.mkOption {
                      type = lib.types.nullOr (
                        lib.types.submodule {
                          options = {
                            user = lib.mkOption {
                              type = lib.types.str;
                              description = "User that should own the file";
                            };
                            group = lib.mkOption {
                              type = lib.types.str;
                              description = "Group that should own the file";
                            };
                          };
                        }
                      );
                      default = null;
                      description = ''
                        Optional user and group that should own the templated file inside the container.
                        This will run run `podman unshare chown <user:group> <destPath>` on the templated file.
                      '';
                    };
                  };
                }
              );
              default = [];
              description = ''
                Bind mount that will render the template with `gomplate`.
                The resulting file will be mounted into the container.

                All environment variables from the `environment` and `extraEnv` options will be available for
                substitution.

                See

                - <https://docs.gomplate.ca/>
                - <https://github.com/hairyhenderson/gomplate>
              '';
              example = lib.literalExpression ''
                [
                  {
                    templatePath = pkgs.writeText "some-template" '''
                      Hello {{ env.GetEnv "USER" "you" }}
                      Secret Password is: {{ file.ReadFile "/run/secrets/some_secret" }}
                    ''';
                    destPath = "/run/secrets/templated_file";
                  }
                ]
              '';
            };

            socketActivation = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    port = mkOption {
                      type = types.oneOf [
                        types.str
                        types.port
                      ];
                      description = "Port that the socket should listen on";
                    };
                    fileDescriptorName = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = ''
                        Name of the file descriptor that the socket should use.
                      '';
                    };
                  };
                }
              );
              default = [];
              description = ''
                List of socket activation configurations for this container.
                Each entry should specify a port and optionally a file descriptor name.
                This will create a systemd socket that activates the container when accessed.

                Will be used by containers like Traefik by default. Allows the container to access real-ip
                without the request being proxied through pasta/slirp4netns.

                For details regarding rootless Podman networking and socket activation,
                see: <https://github.com/eriksjolund/podman-networking-docs>
              '';
            };

            stack = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Stack that a container is part of.
                For every stack, a Podman networking will be crearted that the respective container will be connected to.
              '';
            };
          };

          config = let
            envFromFileContentLocation = "/run/user/${toString globalConf.nps.hostUid}/${name}/extra_env/from_file_content";
            envFromTemplateLocation = "/run/user/${toString globalConf.nps.hostUid}/${name}/extra_env/from_template_string";
            envFromCommandLocation = "/run/user/${toString globalConf.nps.hostUid}/${name}/extra_env/from_command";
            mkTemplateMountSource = fileName: "/run/user/${toString globalConf.nps.hostUid}/${name}/template_mounts/${builtins.baseNameOf fileName}";

            extraLiteralEnv = config.extraEnv |> lib.filterAttrs (_: v: !lib.isAttrs v);
            extraFileContentEnv =
              config.extraEnv
              |> lib.filterAttrs (_: v: lib.isAttrs v && v.fromFile != null)
              |> lib.mapAttrs (_: v: v.fromFile);
            extraTemplateEnv =
              config.extraEnv
              |> lib.filterAttrs (_: v: lib.isAttrs v && v.fromTemplate != null)
              |> lib.mapAttrs (_: v: v.fromTemplate);
            extraCommandEnv =
              config.extraEnv
              |> lib.filterAttrs (_: v: lib.isAttrs v && v.fromCommand != null)
              |> lib.mapAttrs (_: v: v.fromCommand);
          in
            lib.mkMerge [
              #globalConf.nps.defaultContainerSettings

              {
                autoUpdate = lib.mkDefault "registry";

                network = lib.mkIf (config.stack != null) [config.stack];
                dependsOn =
                  (map (
                      sa:
                        mkSocketName {
                          inherit name;
                          port = sa.port;
                        }
                    )
                    config.socketActivation)
                  ++ lib.optional (builtins.any (lib.hasPrefix "${globalConf.nps.socketLocation}:") config.volumes) "podman.socket";

                environment =
                  {
                    TZ = lib.mkDefault globalConf.nps.defaultTz;
                  }
                  // extraLiteralEnv
                  // lib.mapAttrs (_: v: v.destPath) config.fileEnvMount;
                environmentFile =
                  lib.optional (extraFileContentEnv != {}) envFromFileContentLocation
                  ++ lib.optional (extraTemplateEnv != {}) envFromTemplateLocation
                  ++ lib.optional (extraCommandEnv != {}) envFromCommandLocation;

                volumes = lib.mkMerge [
                  (lib.attrValues config.volumeMap)
                  (lib.mkAfter ((config.fileEnvMount |> lib.attrValues |> lib.map (v: "${v.sourcePath}:${v.destPath}"))
                      ++ (config.templateMount |> lib.map (m: "${mkTemplateMountSource m.destPath}:${m.destPath}"))))
                ];

                extraConfig = {
                  Unit = {
                    Requires = config.dependsOn ++ config.dependsOnContainer;
                    Wants = config.wants ++ config.wantsContainer;
                    After = lib.flatten [config.dependsOn config.dependsOnContainer config.wants config.wantsContainer];

                    StartLimitIntervalSec = lib.mkDefault "120";
                    StartLimitBurst = lib.mkDefault 5;
                  };
                  Service = {
                    # Try restarting every 5 seconds for a max 5 times
                    RestartSec = lib.mkDefault "5s";
                  };

                  # Automatically create host directories for volumes if they don't exist
                  Service.ExecStartPre = let
                    volumes = map (v: lib.head (lib.splitString ":" v)) (config.volumes or []);
                    volumeDirs = lib.filter (v: lib.hasInfix "/" v && !lib.hasPrefix "/run" v) volumes;
                  in
                    [
                      (lib.getExe (
                        pkgs.writeShellApplication {
                          name = "setup-volumes";
                          runtimeInputs = [pkgs.coreutils];
                          text = (map (v: "[ -e ${v} ] || mkdir -p ${v}") volumeDirs) |> lib.concatStringsSep "\n";
                        }
                      ))
                    ]
                    ++ lib.optional (extraFileContentEnv != {} || extraTemplateEnv != {} || extraCommandEnv != {} || config.templateMount != [])
                    (
                      lib.getExe (
                        pkgs.writeShellApplication {
                          name = "create-extra-files";
                          runtimeInputs = [
                            pkgs.coreutils
                            pkgs.gomplate
                            globalConf.nps.package
                          ];
                          bashOptions = [
                            "errexit"
                            "nounset"
                            "pipefail"
                          ];
                          text = let
                            literalEnvFile = pkgs.writeText "${name}-literal-env" (
                              config.environment
                              |> lib.mapAttrsToList (name: value: ''${name}=${toString value}'')
                              |> lib.concatStringsSep "\n"
                            );
                          in
                            ''
                              # Podman/Docker retain quotes etc. in .env files, so parse them specially to match that behavior
                              # See <https://github.com/containers/podman/issues/19565>
                              load_env_file() {
                                local file="$1"
                                [ -f "$file" ] || return 0

                                while IFS= read -r line || [[ -n "$line" ]]; do
                                  # skip empty lines and comments
                                  [ -z "$line" ] && continue
                                  case "$line" in
                                    \#*) continue ;;
                                  esac

                                  # skip lines without '='
                                  [[ "$line" == *"="* ]] || continue

                                  local name="''${line%%=*}";
                                  local value="''${line#*=}";

                                  export "$name=$value"
                                done < "$file"
                              }

                            ''
                            + lib.optionalString (extraFileContentEnv != {}) ''
                              # Write file-based envs to file
                              install -D -m 600 /dev/null ${envFromFileContentLocation}
                              {
                              ${
                                extraFileContentEnv
                                |> lib.mapAttrsToList (name: path: ''echo "${name}=$(<${path})"'')
                                |> lib.concatStringsSep "\n"
                              }
                              } > ${envFromFileContentLocation}
                            ''
                            + lib.optionalString (extraTemplateEnv != {}) ''
                              # Export all env vars so gomplate can use them for the template
                              load_env_file ${literalEnvFile}
                              load_env_file ${envFromFileContentLocation}

                              # Write template-based env variables to a new file using gomplate
                              install -D -m 600 /dev/null ${envFromTemplateLocation}
                              gomplate -f ${
                                pkgs.writeText "env-template-${name}" (
                                  extraTemplateEnv
                                  |> lib.mapAttrsToList (name: template: ''${name}=${template}'')
                                  |> lib.concatStringsSep "\n"
                                )
                              } > ${envFromTemplateLocation}
                            ''
                            + lib.optionalString (extraCommandEnv != {}) ''
                              # Export all env vars so they can be used within the command
                              load_env_file ${literalEnvFile}
                              load_env_file ${envFromFileContentLocation}
                              load_env_file ${envFromTemplateLocation}

                              # Eval commands first to propagate errors (if any)
                              ${extraCommandEnv
                                |> lib.mapAttrsToList (name: command: ''
                                  ${name}="$(${command})";
                                '')
                                |> lib.concatStringsSep "\n"}

                              # Write command-based env variables to a new file
                              install -D -m 600 /dev/null ${envFromCommandLocation}
                              {
                              ${
                                extraCommandEnv
                                |> lib.mapAttrsToList (name: command: ''echo "${name}=''$${name}"'')
                                |> lib.concatStringsSep "\n"
                              }
                              } > ${envFromCommandLocation}
                            ''
                            + lib.optionalString (config.templateMount != []) ''
                              # Export all env vars so gomplate can use them for the template
                              load_env_file ${literalEnvFile}
                              load_env_file ${envFromFileContentLocation}
                              load_env_file ${envFromTemplateLocation}
                              load_env_file ${envFromCommandLocation}

                              ${
                                config.templateMount
                                |> lib.map (
                                  m: ''
                                    install -D -m 600 /dev/null ${mkTemplateMountSource m.destPath}
                                    gomplate -f ${m.templatePath} > ${mkTemplateMountSource m.destPath}
                                    ${lib.optionalString (m.chown != null)
                                      "podman unshare chown ${m.chown.user}:${m.chown.group} ${mkTemplateMountSource m.destPath}"}
                                  ''
                                )
                                |> lib.concatStringsSep "\n"
                              }
                            '';
                        }
                      )
                    );
                };
              }
            ];
        }
      )
    );
  };

  config = {
    assertions = [
      (
        let
          baseMessage = "When using `extraEnv` with `fromFile`, `fromTemplate` or `fromCommand`, exactly one of them must be set.";

          failures =
            lib.concatMap
            (
              containerName: let
                c = config.services.podman.containers.${containerName};
              in
                lib.concatMap
                (
                  envName: let
                    v = c.extraEnv.${envName};
                    count =
                      builtins.length
                      (builtins.filter (x: x != null)
                        [v.fromFile v.fromTemplate v.fromCommand]);
                  in
                    lib.optional
                    (lib.isAttrs v && count != 1)
                    "container=${containerName}, extraEnv=${envName}, set=${toString count}"
                )
                (builtins.attrNames c.extraEnv)
            )
            (builtins.attrNames config.services.podman.containers);
        in {
          assertion = failures == [];
          message =
            baseMessage
            + "\n\nThe following entries are invalid:\n"
            + lib.concatStringsSep "\n" failures;
        }
      )
    ];

    # For every stack, define a default network.
    services.podman.networks = let
      stacks =
        config.services.podman.containers
        |> builtins.attrValues
        |> builtins.filter (c: c.stack != null)
        |> builtins.map (c: c.stack);
    in
      lib.genAttrs stacks (s: lib.mkDefault {driver = "bridge";});

    # Create sockets for socketActivated containers
    systemd.user.sockets = let
      containers = lib.filterAttrs (n: v: v.socketActivation != []) config.services.podman.containers;
      mkSockets = name: container:
        map (
          sa:
            lib.nameValuePair
            (mkSocketName {
              inherit name;
              port = sa.port;
              suffix = "";
            })
            {
              Socket.ListenStream = "${toString sa.port}";
              Socket.ListenDatagram = "${toString sa.port}";
              Socket.Service = "podman-${name}.service";
              Socket.FileDescriptorName = lib.mkIf (sa.fileDescriptorName != null) sa.fileDescriptorName;
              Install.WantedBy = ["sockets.target"];
            }
        )
        container.socketActivation;
      sockets = (lib.mapAttrsToList mkSockets containers) |> lib.flatten |> lib.listToAttrs;
    in
      sockets;
  };
}
