{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nix-darwin,
      ...
    }:
    {
      darwinConfigurations = {
        kage = nix-darwin.lib.darwinSystem {
          modules = [
            ./configuration.nix
            (
              { pkgs, ... }:
              {
                networking.hostName = "kage";
                system.primaryUser = "kon";
                system.configurationRevision = self.rev or self.dirtyRev or null;
                environment.systemPackages = with pkgs; [
                  cargo-tarpaulin
                  cargo-fuzz
                  ollama
                  audacity
                  ffmpeg
                  deno
                  nodejs
                  texliveFull
                  ghostscript
                ];
              }
            )
          ];
        };
        CF0022 = nix-darwin.lib.darwinSystem {
          modules = [
            ./configuration.nix
            (
              { pkgs, ... }:
              {
                networking.hostName = "CF0022";
                system.primaryUser = "um003415";
                system.configurationRevision = self.rev or self.dirtyRev or null;
                environment.systemPackages = with pkgs; [
                  claude-code
                ];
              }
            )
          ];
        };
      };
    };
}
