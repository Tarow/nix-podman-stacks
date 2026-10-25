{
  description = "Collection of opinionated rootless Podman stacks";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    search = {
      url = "github:NuschtOS/search";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    ...
  } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    lib = nixpkgs.lib;
  in {
    homeModules = import ./modules/module_list.nix;
    # Public helpers, mainly `lib.mkIntegrationTest`. See docs/book/testing.md.
    lib = import ./lib {
      inherit
        self
        home-manager
        lib
        ;
    };
    templates.default = {
      description = "Nix Podman Stacks Starter";
      path = ./template;
    };
    homeConfigurations.ci = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      modules = [
        sops-nix.homeManagerModules.sops
        self.homeModules.nps
        {
          home.stateVersion = "26.05";
          home.username = "ci";
          home.homeDirectory = "/home/ci";
        }
        ./ci_config.nix
      ];
    };

    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        docs = import ./docs/default.nix {
          inherit
            self
            pkgs
            inputs
            system
            lib
            ;
          inherit (self.packages.${system}) optionsJSON;
        };
      in
        docs
        // {
          inspect = import ./packages/inspect.nix {inherit pkgs;};
        }
    );

    # NixOS VM integration tests (only defined for Linux systems and only for
    # stacks that ship a `modules/<stack>/vm-test.nix` file). Kept outside of
    # `packages` and under a custom output because `nix flake check` realises
    # every `packages.<system>` derivation, which would build all the heavy VM
    # test closures on every check. Use `nix build
    # .#integrationTests.x86_64-linux.<stack>-integration` to run a test.
    # Built via `self.lib.mkIntegrationTest`, the same entry point consumers use.
    integrationTests = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        lib.optionalAttrs (builtins.elem system [
          "aarch64-linux"
          "x86_64-linux"
        ]) (let
          stackNames = builtins.filter (
            name: builtins.pathExists ./modules/${name}/vm-test.nix
          ) (builtins.attrNames (import ./modules/module_list.nix));
        in
          (lib.listToAttrs (map (name: {
              name = "${name}-integration";
              value = self.lib.mkIntegrationTest {
                inherit pkgs;
                name = "${name}-integration";
                modules = [./modules/${name}/vm-test.nix];
              };
            })
            stackNames))
          // {
            # End-to-end test of the shipped template config
            template-integration = self.lib.mkIntegrationTest {
              inherit pkgs;
              name = "template-integration";
              modules = [
                sops-nix.homeManagerModules.sops
                ./template/sops.nix
                ./template/stacks.nix
                # Traefik would otherwise try to issue a real Let's Encrypt certificate.
                self.lib.stackTestModules.traefik
              ];
              memorySize = 4096;
              diskSize = 20480;
              waitTimeout = 1800;
            };
          })
    );

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
