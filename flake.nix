{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  outputs = { self, nixpkgs, nixos-hardware }: {
    nixosConfigurations.mame = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./mame/configuration.nix
      ];
    };
    nixosConfigurations.poi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./poi/configuration.nix
        nixos-hardware.nixosModules.raspberry-pi-4
      ];
    };
    nixosConfigurations.hato = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hato/configuration.nix
      ];
    };
  };
}
