{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  # SSH authorized keys, single source of truth (not a flake, just key files).
  inputs.pubkeys.url = "github:golddranks/pubkeys";
  inputs.pubkeys.flake = false;
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      nixpkgs,
      nixos-hardware,
      pubkeys,
      sops-nix,
      ...
    }:
    let
      mkHost =
        { system, modules }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit pubkeys; };
          modules = modules ++ [ sops-nix.nixosModules.sops ];
        };
    in
    {
      nixosConfigurations.cafe = mkHost {
        system = "x86_64-linux";
        modules = [ ./cafe/configuration.nix ];
      };
      nixosConfigurations.bead = mkHost {
        system = "aarch64-linux";
        modules = [
          ./bead/configuration.nix
          nixos-hardware.nixosModules.raspberry-pi-4
        ];
      };
      nixosConfigurations.hato = mkHost {
        system = "x86_64-linux";
        modules = [ ./hato/configuration.nix ];
      };
    };
}
