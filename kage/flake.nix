{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nix-darwin, ... }:
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .
      darwinConfigurations."kage" = nix-darwin.lib.darwinSystem {
        modules = [
          ./configuration.nix
          {
            system.configurationRevision = self.rev or self.dirtyRev or null;
          }
        ];
      };
    };
}
