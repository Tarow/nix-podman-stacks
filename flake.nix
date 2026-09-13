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

        # NixOS VM integration tests. Only defined for Linux systems and only
        # for stacks that ship a `modules/<stack>/vm-test.nix` file.
        integrationTests =
          lib.optionalAttrs (builtins.elem system [
            "aarch64-linux"
            "x86_64-linux"
          ]) (let
            stackNames = builtins.filter (
              name: builtins.pathExists ./modules/${name}/vm-test.nix
            ) (builtins.attrNames (import ./modules/module_list.nix));
            mkIntegrationTest = stackName:
              (import ./tests/vm.nix {
                inherit
                  pkgs
                  home-manager
                  self
                  ;
              })
              stackName;
          in
            lib.listToAttrs (map (name: {
                name = "${name}-integration";
                value = mkIntegrationTest name;
              })
              stackNames));
      in
        docs
        // integrationTests
    );

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
