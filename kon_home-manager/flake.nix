{
  description = "Home Manager configuration of kon";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ld-vscode = {
      url = "github:scottstephens/nix-ld-vscode/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-ld-vscode }:
    let
      modules = [
        ./home.nix
        nix-ld-vscode.nixosModules.default
      ];
    in {
      homeConfigurations = {
        "kon@mame" = home-manager.lib.homeManagerConfiguration {
          inherit modules;
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
        };
        "kon@hato" = home-manager.lib.homeManagerConfiguration {
          inherit modules;
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
        };
        "kon@poi" = home-manager.lib.homeManagerConfiguration {
          inherit modules;
          pkgs = nixpkgs.legacyPackages."aarch64-linux";
        };
      };
    };
}
