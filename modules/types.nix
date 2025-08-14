lib: with lib.types; rec {
  fromFileSubmodule = (
    submodule {
      options.fromFile = lib.mkOption {
        type = path;
        description = "Path to file containing the variable value.";
      };
    }
  );

  primitiveOrFileContent = attrsOf (oneOf [
    bool
    int
    str
    path

    fromFileSubmodule
  ]);

  envSource = attrsOf primitiveOrFileContent;
}
