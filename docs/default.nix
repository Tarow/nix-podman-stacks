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

  siteUrl = "https://tarow.github.io/nix-podman-stacks/docs";

  siteDescription = "Deploy self-hosted services with Nix, Home Manager, and Podman Quadlets. Pre-configured integrations with Traefik, Homepage, Grafana, Authelia, and more - so everything works together out of the box.";

  vitepressConfig = builtins.toJSON {
    title = "Nix Podman Stacks";

    description = siteDescription;

    sitemap = {
      hostname = "${siteUrl}/";
    };

    head = [
      [
        "meta"
        {
          name = "description";
          content = siteDescription;
        }
      ]
      [
        "meta"
        {
          property = "og:type";
          content = "website";
        }
      ]
      [
        "meta"
        {
          property = "og:title";
          content = "Nix Podman Stacks";
        }
      ]
      [
        "meta"
        {
          property = "og:description";
          content = siteDescription;
        }
      ]
      [
        "meta"
        {
          property = "og:url";
          content = siteUrl;
        }
      ]
      [
        "meta"
        {
          property = "og:site_name";
          content = "Nix Podman Stacks";
        }
      ]
      [
        "meta"
        {
          name = "twitter:card";
          content = "summary";
        }
      ]
      [
        "meta"
        {
          name = "twitter:title";
          content = "Nix Podman Stacks";
        }
      ]
      [
        "meta"
        {
          name = "twitter:description";
          content = siteDescription;
        }
      ]
      [
        "link"
        {
          rel = "canonical";
          href = siteUrl;
        }
      ]
      [
        "link"
        {
          rel = "icon";
          type = "image/svg+xml";
          href = "${siteUrl}/favicon.svg";
        }
      ]
    ];

    themeConfig = {
      logo = "/images/nix-podman-logo.png";

      nav = [
        {
          text = "Home";
          link = "/index";
        }
        {
          text = "Getting Started";
          link = "/getting-started";
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
              link = "/stacks/";
            }
          ];
        }
        {
          text = "Guides";
          items = [
            {
              text = "Backups";
              link = "/backups";
            }
            {
              text = "Secrets & Templating";
              link = "/secrets-templating";
            }
            {
              text = "Examples";
              link = "/examples";
            }
          ];
        }
      ];

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
              text = "Backups";
              link = "/backups";
            }
            {
              text = "Secrets & Templating";
              link = "/secrets-templating";
            }
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

        mkdir -p .vitepress
        cp ${mkVitepressConfig} .vitepress/config.mts

        mkdir -p ./stacks
        ${lib.concatMapStrings mkStackOptionsFile stackNames}

        # The built-in VPDocAsideOutline imports VPDocOutlineItem via a direct
        # ES import, so theme-level app.component overrides are silently
        # ignored. Overwrite the shipped component with our version that strips
        # the NixOS option path prefixes from the outline text.
        cp .vitepress/theme/VPDocOutlineItem.vue \
          node_modules/vitepress/dist/client/theme-default/components/VPDocOutlineItem.vue

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

      # Serve the theme-config images (hero image, navbar logo) referenced via
      # relative paths. These are theme data values (not markdown/vue assets),
      # so VitePress does not bundle them - copy the source images alongside the
      # output so the relative URLs resolve, while keeping the public directory
      # for robots.txt and favicon only.
      cp -r ./images $out/images

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
