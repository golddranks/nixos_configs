{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  # SSH authorized keys, single source of truth (not a flake, just key files).
  inputs.pubkeys.url = "github:golddranks/pubkeys";
  inputs.pubkeys.flake = false;

  outputs = { self, nixpkgs, nixos-hardware, pubkeys }: {
    nixosConfigurations.mame = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit pubkeys; };
      modules = [
        ./mame/configuration.nix
      ];
    };
    nixosConfigurations.poi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit pubkeys; };
      modules = [
        ./poi/configuration.nix
        nixos-hardware.nixosModules.raspberry-pi-4
      ];
    };
    nixosConfigurations.hato = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit pubkeys; };
      modules = [
        ./hato/configuration.nix
      ];
    };
  };
}
