{
  imports = [../it-tools/vm-test.nix];
  nps.stacks.sablier = {
    enable = true;
    settings.sessions.default-duration = "10m";
  };

  # Exercises the generated middleware and the [X-Sablier] unit section.
  nps.stacks.it-tools.containers.it-tools.sablier = {
    enable = true;
    group = "it-tools";
    idleReplicas = "1";
    middleware = {
      sessionDuration = "10m";
      failOpen = true;
      dynamic.theme = "matrix";
    };
  };
}
