{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  # cafe's vaultwarden tracks unstable; pinned via flake.lock instead of a
  # fetchTarball at eval time, so evals are reproducible.
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  # SSH authorized keys, single source of truth (not a flake, just key files).
  inputs.pubkeys.url = "github:golddranks/pubkeys";
  inputs.pubkeys.flake = false;
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      pubkeys,
      sops-nix,
      ...
    }:
    let
      mkHost =
        { system, modules }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pubkeys;
            unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
          };
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
        modules = [ ./bead/configuration.nix ];
      };
      nixosConfigurations.hato = mkHost {
        system = "x86_64-linux";
        modules = [ ./hato/configuration.nix ];
      };
    };
}
