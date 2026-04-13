{
  description = "Nix Podman Stacks Starter";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-podman-stacks = {
      url = "github:Tarow/nix-podman-stacks/v0.6.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    home-manager,
    nixpkgs,
    sops-nix,
    nix-podman-stacks,
    ...
  }: let
    # Replace with your system architecture (if necessary)
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    homeConfigurations.myhost = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        sops-nix.homeManagerModules.sops
        nix-podman-stacks.homeModules.nps
        {
          home.stateVersion = "25.11";

          # Replace with your own username and home directory
          home.username = "someuser";
          home.homeDirectory = "/home/someuser";
        }
        ./sops.nix
        ./stacks.nix
      ];
    };
  };
}
