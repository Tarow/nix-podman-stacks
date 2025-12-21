{
  self,
  pkgs,
  inputs,
  lib,
  system,
  optionsJSON,
  ...
}: let
  eval = lib.evalModules {
    modules = [
      {config._module.check = false;}
      {_module.args.pkgs = pkgs;}
      self.homeModules.nps
    ];
  };
  gitHubDeclaration = user: repo: branch: subpath: {
    url = "https://github.com/${user}/${repo}/blob/${branch}/${subpath}";
    name = "<${repo}/${subpath}>";
  };

  nixPodmanStacksPath = toString self;
  hmPath = toString inputs.home-manager;
  hasAnyLocPrefix = prefixes: loc:
    lib.any (prefix: hasLocPrefix prefix loc) prefixes;
  hasLocPrefix = prefix: loc: lib.lists.take (lib.length prefix) loc == prefix;

  mkOptionsDoc = {
    options ? eval.options,
    wantPrefix ? [],
    excludePrefix ? [],
  }:
    pkgs.nixosOptionsDoc {
      documentType = "none";
      warningsAreErrors = false;

      inherit options;

      transformOptions = option:
        option
        // {
          visible =
            option.visible
            && option.loc
            != [
              "services"
              "podman"
              "containers"
            ]
            && (lib.hasPrefix nixPodmanStacksPath (toString option.declarations))
            && (wantPrefix == [] || hasAnyLocPrefix wantPrefix option.loc)
            && !(excludePrefix != [] && hasAnyLocPrefix excludePrefix option.loc);
        }
        // {
          declarations =
            map (
              decl:
                if lib.hasPrefix nixPodmanStacksPath (toString decl)
                then
                  gitHubDeclaration "tarow" "nix-podman-stacks" "main" (
                    lib.removePrefix "/" (lib.removePrefix nixPodmanStacksPath (toString decl))
                  )
                else if lib.hasPrefix hmPath (toString decl)
                then
                  gitHubDeclaration "nix-community" "home-manager" "master" (
                    lib.removePrefix "/" (lib.removePrefix hmPath (toString decl))
                  )
                else null
            )
            option.declarations
            |> lib.filter (d: d != null);
        };
    };
  settingsOptions = mkOptionsDoc {
    wantPrefix = [["nps"]];
    excludePrefix = [
      [
        "nps"
        "stacks"
      ]
      ["nps" "containers"]
    ];
  };
  containerOptions = mkOptionsDoc {
    wantPrefix = [
      [
        "services"
        "podman"
      ]
    ];
  };

  stackDocs = let
    stackNames = lib.attrNames eval.options.nps.stacks;
  in
    stackNames
    |> lib.map (
      stack: (lib.nameValuePair stack (mkOptionsDoc {
        wantPrefix = [
          [
            "nps"
            "stacks"
            stack
          ]
        ];
      }))
    )
    |> lib.listToAttrs;

  filteredOptions = pkgs.nixosOptionsDoc {
    documentType = "none";
    warningsAreErrors = false;
    inherit (eval) options;
  };
in {
  inherit (filteredOptions) optionsJSON;
  book = pkgs.stdenv.mkDerivation {
    pname = "nix-podman-stacks-docs-book";
    version = "0.0.1";
    src = self;

    nativeBuildInputs = with pkgs; [
      mdbook
      mdbook-alerts
      mdbook-linkcheck
    ];

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild
      mkdir -p src/images

      cp docs/mdbook/book.toml .
      cp docs/mdbook/src/* src/
      cp ${self}/README.md src/introduction.md
      cp ${self}/images/* src/images/
      cat ${settingsOptions.optionsCommonMark} >> src/settings-options.md
      cat ${containerOptions.optionsCommonMark} >> src/container-options.md

      # Generate a subpage for each stack
      ${lib.concatMapAttrsStringSep "\n" (stack: opts: ''
          cat ${opts.optionsCommonMark} > src/stack-${stack}-options.md
          echo "  - [${stack}](./stack-${stack}-options.md)" >> src/SUMMARY.md
        '')
        stackDocs}
      mdbook build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mv book/html $out
      runHook postInstall
    '';
  };

  vitepress = pkgs.buildNpmPackage {
    name = "nps-docs";
    src = ./vitepress;

    npmDeps = pkgs.importNpmLock {
      npmRoot = ./vitepress;
    };

    inherit (pkgs.importNpmLock) npmConfigHook;
    env.NPS_OPTIONS_JSON = optionsJSON;

    # VitePress hangs if you don't pipe the output into a file
    buildPhase = ''
      runHook preBuild

        local exit_status=0
        npm run build > build.log 2>&1 || {
            exit_status=$?
            :
        }
        cat build.log
        return $exit_status

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mv .vitepress/dist $out

      runHook postInstall
    '';
  };

  search = inputs.search.packages.${system}.mkSearch {
    modules = [self.homeModules.nps];
    specialArgs.pkgs = pkgs;
    urlPrefix = "https://github.com/Tarow/nix-podman-stacks/blob/main/";
    title = "Nix Podman Stacks Search";
    baseHref = "/nix-podman-stacks/search/";
  };
}
