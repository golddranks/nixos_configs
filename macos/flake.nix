{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    claude-code-nix.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    {
      self,
      nix-darwin,
      claude-code-nix,
      nixpkgs-unstable,
      ...
    }:
    {
      darwinConfigurations = {
        kage = nix-darwin.lib.darwinSystem {
          modules = [
            ./configuration.nix
            (
              { pkgs, ... }:
              let
                unstable = import nixpkgs-unstable {
                  system = pkgs.system;
                  config.allowUnfree = true;
                };
              in
              {
                networking.hostName = "kage";
                system.primaryUser = "kon";
                system.configurationRevision = self.rev or self.dirtyRev or null;
                environment.systemPackages = with pkgs; [
                  unstable.cargo-tarpaulin
                  unstable.cargo-fuzz
                  unstable.lima
                  ollama
                  audacity
                  ffmpeg
                  deno
                  nodejs
                  texliveFull
                  ghostscript
                  librsvg
                  claude-code-nix.packages.aarch64-darwin.default
                  bun
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
                  poetry
                  google-cloud-sdk
                  awscli2
                  claude-code-nix.packages.aarch64-darwin.default
                ];
              }
            )
          ];
        };
      };
    };
}
