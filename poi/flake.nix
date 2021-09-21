{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  inputs.checkup.url = "github:golddranks/checkup-nix";

  outputs = { self, nixpkgs, nixos-hardware, checkup }: {
    nixosConfigurations.poi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        nixos-hardware.nixosModules.raspberry-pi-4
        checkup.nixosModules.checkup
      ];
    };
  };
}
