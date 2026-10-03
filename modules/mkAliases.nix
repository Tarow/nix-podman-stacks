config: lib: stackName: containers:
(lib.flatten containers
  |> (map (c: [
    (lib.doRename {
      from = [
        "nps"
        "stacks"
        stackName
        "containers"
        c
      ];
      to = [
        "services"
        "podman"
        "containers"
        c
      ];
      use = x: x;
      warn = false;
      visible = true;
      condition = config.nps.stacks.${stackName}.enable && (config.nps.stacks.${stackName}.${c}.enable or true);
    })
    (lib.doRename {
      from = [
        "nps"
        "containers"
        c
      ];
      to = [
        "services"
        "podman"
        "containers"
        c
      ];
      use = x: x;
      warn = false;
      visible = true;
      condition = config.nps.stacks.${stackName}.enable && (config.nps.stacks.${stackName}.${c}.enable or true);
    })
  ]))
  |> lib.flatten)
++ [
  {
    # Catches containers that joined the stack without being listed above.
    config.assertions = let
      missing = builtins.filter (c: !(lib.elem c (lib.flatten containers))) (
        builtins.attrNames (
          lib.filterAttrs (_: c: c.stack or null == stackName) config.services.podman.containers
        )
      );
    in [
      {
        assertion = missing == [];
        message = ''
          Container(s) ${lib.concatStringsSep ", " missing} belong to stack '${stackName}' but are missing in the mkAliases.nix container list.
        '';
      }
    ];
  }
]
