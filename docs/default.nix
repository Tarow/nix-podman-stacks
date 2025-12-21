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
    cat > ./stacks/${stack}.md <<'EOF'
    ---
    title: ${stack}
    ---

    # {{ $frontmatter.title }}

    <script setup>
    import { data } from "../nps.data.ts";
    import { RenderDocs } from "easy-nix-documentation";
    </script>

    ## Stack Options

    <RenderDocs :options="data" :include="/nps\.stacks\.${stack}\.*/" />
    EOF
  '';

  mkVitepressConfig = pkgs.writeText "vitepress-config.mts" ''
    import { defineConfig } from "vitepress";

    // https://vitepress.dev/reference/site-config
    export default defineConfig({
      title: "Nix Podman Stacks",
      description: "",
      // base: "/mnw/", // Manually pass with --base
      themeConfig: {
        // https://vitepress.dev/reference/default-theme-config
        search: {
          provider: "local",
        },
        sidebar: [
          {
            items: [
              { text: "Home", link: "/index" },
            ],
          },
          {
            text: 'Options',
            items: [
              { text: "Stacks", link: "/options" },
              ${lib.concatMapStringsSep "\n" (stackName: ''
        { text: "${stackName}", link: "/stacks/${stackName}" },
      '')
      stackNames}
            ],
          },
        ],

        socialLinks: [
          { icon: "github", link: "https://github.com/Tarow/nix-podman-stacks" },
        ],

        outline: {
          level: "deep",
        },
      },
      vite: {
        ssr: {
          noExternal: "easy-nix-documentation",
        },
      },
    });

  '';
in {
  inherit (filteredOptions) optionsJSON;

  book = pkgs.buildNpmPackage {
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

        mkdir .vitepress
        cp ${mkVitepressConfig} .vitepress/config.mts

        mkdir -p ./stacks
        ${lib.concatMapStrings mkStackOptionsFile stackNames}

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
      mkdir -p $out/.vitepress
      mv .vitepress/config.mts $out/.vitepress/config.mts

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
