{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  inputs.common.url = "path:../common";

  outputs = { self, nixpkgs, nixos-hardware, common }: {
    nixosConfigurations.poi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        nixos-hardware.nixosModules.raspberry-pi-4
      ];
    };
  };
}
