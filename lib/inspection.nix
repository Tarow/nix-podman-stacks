{
  lib,
  config,
}: let
  containers = config.services.podman.containers;

  stackContainers = lib.filterAttrs (_: container: container.stack != null) containers;
  stackNames = lib.unique (lib.mapAttrsToList (_: container: container.stack) stackContainers);

  toStringValue = value:
    if builtins.isPath value
    then toString value
    else if builtins.isBool value || builtins.isInt value || builtins.isFloat value
    then toString value
    else if value == null
    then "null"
    else value;

  normalizeValue = value:
    if builtins.isPath value
    then toString value
    else if builtins.isAttrs value
    then lib.mapAttrs (_: normalizeValue) value
    else if builtins.isList value
    then map normalizeValue value
    else value;

  normalizeContainerDependency = dependency:
    if lib.hasPrefix "podman-" dependency && lib.hasSuffix ".service" dependency
    then lib.removeSuffix ".service" (lib.removePrefix "podman-" dependency)
    else dependency;

  normalizeExtraEnv = values: let
    normalized = normalizeValue values;
  in
    lib.filterAttrs (_: value: value != null && !(builtins.isAttrs value && value == {})) (
      lib.mapAttrs (
        _: value:
          if builtins.isAttrs value
          then lib.filterAttrs (_: field: field != null) value
          else value
      )
      normalized
    );

  mkContainer = name: container: let
    network = container.network or null;
    networkNames =
      if network == null
      then []
      else if builtins.isList network
      then network
      else [network];
  in
    normalizeValue {
      inherit name;
      stack = container.stack;
      image = container.image;
      networks = networkNames;
      port = container.port or null;
      volumes = container.volumes or [];
      volumeMap = container.volumeMap or {};
      environment = container.environment or {};
      extraEnv = normalizeExtraEnv (container.extraEnv or {});
      environmentFile = container.environmentFile or [];
      dependencies = {
        requires = lib.unique (map normalizeContainerDependency (container.dependsOnContainer or []) ++ (container.dependsOn or []));
        wants = lib.unique (map normalizeContainerDependency (container.wantsContainer or []) ++ (container.wants or []));
      };
      integrations = {
        traefik = {
          name = container.traefik.name or null;
          serviceHost = container.traefik.serviceHost or null;
          serviceUrl = container.traefik.serviceUrl or null;
          expose = container.expose or null;
        };
        dashboard = container.dashboard or {};
      };
    };

  stackData = lib.mapAttrsToList (name: container: mkContainer name container) stackContainers;

  networks = lib.unique (lib.concatMap (container: container.networks) stackData);

  edges =
    lib.concatMap (
      container:
        map (dependency: {
          from = container.name;
          to = dependency;
          kind = "requires";
        })
        container.dependencies.requires
        ++ map (dependency: {
          from = container.name;
          to = dependency;
          kind = "wants";
        })
        container.dependencies.wants
        ++ map (network: {
          from = container.name;
          to = network;
          kind = "network";
        })
        container.networks
        ++ lib.optional (container.integrations.traefik.name != null) {
          from = container.name;
          to = "route:${container.integrations.traefik.name}";
          kind = "route";
        }
    )
    stackData;

  data = {
    inherit networks edges;
    containers = stackData;
  };

  renderContainer = container: let
    field = label: value: let
      labelWidth = 12;
      padding = lib.concatStrings (lib.replicate (labelWidth - builtins.stringLength label) " ");
    in "  ${label}:${padding} ${value}";
    formatList = values:
      if values == []
      then "none"
      else lib.concatStringsSep ", " (map toStringValue values);
    volumeLines = map (volume: "    ${volume}") container.volumes;
    environmentLines =
      lib.mapAttrsToList (name: value: "    ${name}=${toStringValue value}") container.environment;
    extraEnvironmentLines =
      lib.mapAttrsToList (
        name: value:
          "    ${name}="
          + (
            if builtins.isAttrs value
            then builtins.toJSON value
            else toStringValue value
          )
      )
      container.extraEnv;
    dashboardParts = lib.filter (value: value != null) [
      (container.integrations.dashboard.name or null)
      (container.integrations.dashboard.category or null)
      (container.integrations.dashboard.icon or null)
    ];
    traefikValue =
      if container.integrations.traefik.name == null
      then "not configured"
      else "${toStringValue container.integrations.traefik.serviceUrl} (${
        if container.integrations.traefik.expose == true
        then "public"
        else "private"
      })";
    dashboardValue =
      if dashboardParts == []
      then "not configured"
      else lib.concatStringsSep " / " (map toStringValue dashboardParts);
  in ''
    ${container.name} (${container.stack})
    ${field "Image" (toStringValue container.image)}
    ${field "Networks" (formatList container.networks)}
    ${field "Port" (
      if container.port == null
      then "not configured"
      else toStringValue container.port
    )}
    ${field "Requires" (formatList container.dependencies.requires)}
    ${field "Wants" (formatList container.dependencies.wants)}
    ${field "Traefik" traefikValue}
    ${field "Dashboard" dashboardValue}
      Volumes:
    ${
      if volumeLines == []
      then "    none"
      else lib.concatStringsSep "\n" volumeLines
    }
      Environment (resolved):
    ${
      if environmentLines == []
      then "    none"
      else lib.concatStringsSep "\n" environmentLines
    }
      ExtraEnv sources:
    ${
      if extraEnvironmentLines == []
      then "    none"
      else lib.concatStringsSep "\n" extraEnvironmentLines
    }
      Environment files:
    ${
      if container.environmentFile == []
      then "    none"
      else lib.concatStringsSep "\n" (map (file: "    ${file}") container.environmentFile)
    }
  '';

  escapeDot = value:
    lib.replaceStrings ["\\" "\"" "\n" "\r"] ["\\\\" "\\\"" "\\n" ""] (toString value);

  renderDot = selectedContainers: let
    selectedNetworks = lib.unique (lib.concatMap (container: container.networks) selectedContainers);
    selectedNames = map (container: container.name) selectedContainers;
    routedContainers = lib.filter (container: container.integrations.traefik.name != null) selectedContainers;
    dependencies = lib.unique (lib.concatMap (container: container.dependencies.requires ++ container.dependencies.wants) selectedContainers);
    externalDependencies = lib.filter (dependency: !(builtins.elem dependency selectedNames)) dependencies;
    dependencyTarget = dependency:
      if builtins.elem dependency selectedNames
      then "container:${escapeDot dependency}"
      else "dependency:${escapeDot dependency}";
    nodes =
      map (container: ''"container:${escapeDot container.name}" [label="${escapeDot container.name}\n${escapeDot container.image}"];'') selectedContainers
      ++ map (network: ''"network:${escapeDot network}" [shape=ellipse,label="${escapeDot network}"];'') selectedNetworks
      ++ map (container: ''"route:${escapeDot container.integrations.traefik.name}" [shape=component,label="${escapeDot container.integrations.traefik.serviceHost}\n${escapeDot container.integrations.traefik.serviceUrl}"];'') routedContainers
      ++ map (dependency: ''"dependency:${escapeDot dependency}" [shape=box,label="${escapeDot dependency} (outside selection)"];'') externalDependencies;
    containerEdges =
      lib.concatMap (
        container:
          map (dependency: ''"container:${escapeDot container.name}" -> "${dependencyTarget dependency}" [label="requires"];'') container.dependencies.requires
          ++ map (dependency: ''"container:${escapeDot container.name}" -> "${dependencyTarget dependency}" [style=dashed,label="wants"];'') container.dependencies.wants
          ++ map (network: ''"container:${escapeDot container.name}" -> "network:${escapeDot network}" [style=dotted,label="network"];'') container.networks
          ++ lib.optional (container.integrations.traefik.name != null) ''"container:${escapeDot container.name}" -> "route:${escapeDot container.integrations.traefik.name}" [label="route"];''
      )
      selectedContainers;
  in ''
    digraph nps {
      rankdir=LR;
    ${lib.concatStringsSep "\n" (nodes ++ containerEdges)}
    }
  '';

  mkRender = selectedContainers: {
    summary = lib.concatMapStringsSep "\n" renderContainer selectedContainers;
    json = builtins.toJSON {
      networks = lib.unique (lib.concatMap (container: container.networks) selectedContainers);
      containers = selectedContainers;
      edges =
        lib.filter (
          edge:
            builtins.elem edge.from (map (container: container.name) selectedContainers)
        )
        edges;
    };
    dot = renderDot selectedContainers;
  };

  rendersByStack = lib.genAttrs stackNames (
    stack:
      mkRender (lib.filter (container: container.stack == stack) stackData)
  );
in {
  inherit data;
  render = (mkRender stackData) // {stacks = rendersByStack;};
}
