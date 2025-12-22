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

  filteredOptions = pkgs.nixosOptionsDoc {
    documentType = "none";
    warningsAreErrors = false;
    inherit (eval) options;
  };

  stackNames = lib.attrNames eval.options.nps.stacks;

  mkStackOptionsFile = stack: ''
    echo "# ${stack}" > ./stacks/${stack}.md

    if [ -d "${self}/modules/${stack}" ]; then
      cat ${self}/modules/${stack}/*.md >> ./stacks/${stack}.md
    fi

    cat >> ./stacks/${stack}.md <<'EOF'
    <script setup>
      import { data } from "../nps.data.ts";
      import { RenderDocs } from "easy-nix-documentation";
    </script>

    ## Stack Options
    <RenderDocs :options="data" :include="/nps\.stacks\.${stack}\.*/" />
    EOF
  '';
  stackItems =
    map (stack: {
      text = stack;
      link = "/stacks/${stack}";
    })
    stackNames;

  vitepressConfig = builtins.toJSON {
    title = "Nix Podman Stacks";

    description = "";

    themeConfig = {
      sidebar = [
        {
          items = [
            {
              text = "Home";
              link = "/index";
            }
            {
              text = "Getting Started";
              link = "/getting-started";
            }
          ];
        }
        {
          text = "Options";
          items = [
            {
              text = "Settings";
              link = "/settings-options";
            }
            {
              text = "Container Options";
              link = "/container-options";
            }
            {
              text = "Stacks";
              collapsed = false;
              items = stackItems;
            }
          ];
        }
        {
          items = [
            {
              text = "Examples";
              link = "/examples";
            }
          ];
        }
      ];

      socialLinks = [
        {
          icon = "github";
          link = "https://github.com/Tarow/nix-podman-stacks";
        }
      ];

      outline = {
        level = "deep";
      };
    };

    vite = {
      ssr = {
        noExternal = "easy-nix-documentation";
      };
    };
  };

  mkVitepressConfig = pkgs.writeText "vitepress-config.mts" ''
    import { defineConfig } from "vitepress";
    import { pagefindPlugin } from 'vitepress-plugin-pagefind'
    // https://vitepress.dev/reference/site-config
    const baseConfig = ${vitepressConfig};

    export default defineConfig({
      ...baseConfig,
      vite: {
        ...baseConfig.vite,
        plugins: [pagefindPlugin()],
      },
    });
  '';
in {
  inherit (filteredOptions) optionsJSON;

  book = pkgs.buildNpmPackage {
    name = "nps-docs";
    src = ./book;

    npmDeps = pkgs.importNpmLock {
      npmRoot = ./book;
    };

    inherit (pkgs.importNpmLock) npmConfigHook;
    env.NPS_OPTIONS_JSON = optionsJSON;

    buildPhase = ''
      runHook preBuild

        cp -r ${self}/images .

        mkdir .vitepress
        cp ${mkVitepressConfig} .vitepress/config.mts

        mkdir -p ./stacks
        ${lib.concatMapStrings mkStackOptionsFile stackNames}

        # VitePress hangs if you don't pipe the output into a file
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
