lib:
with lib;
with types;
rec {

  fromFileOrTemplateSubmodule = (
    submodule (
      { config, ... }:
      {
        options = {
          fromFile = mkOption {
            type = nullOr path;
            default = null;
            description = "Path to file containing the variable value.";
            example = "/path/to/file.txt";
          };
          fromTemplate = mkOption {
            type = nullOr str;
            default = null;
            description = ''
              Template string to be used with the file content.
              The template will be processed with `envsubst`, allowing you to use environment variables.

              See <https://github.com/a8m/envsubst>
            '';
            example = "DB_URL=\${DB_USERNAME}:\${DB_PASSWORD}@localhost:5432/mydb";
          };
        };

      }
    )
  );

  primitiveOrSubmodule = (
    oneOf [
      bool
      int
      str
      path

      # Can't use oneOf [fromFileSubmodule fromTemplateSubmodule] unfortunately
      # See https://discourse.nixos.org/t/problems-with-types-oneof-and-submodules/15197
      fromFileOrTemplateSubmodule
    ]
  );

  extraEnv = attrsOf primitiveOrSubmodule;
}
