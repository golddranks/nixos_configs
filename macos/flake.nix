{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pubkeys = {
      url = "github:golddranks/pubkeys";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nix-darwin,
      nixpkgs-unstable,
      pubkeys,
      ...
    }:
    let
      # Exposes the unstable channel as pkgs.unstable.* so every package list
      # can live in configuration.nix regardless of channel.
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      };
      # Everything that isn't host-specific.
      commonModules = [
        ./configuration.nix
        {
          nixpkgs.overlays = [ unstableOverlay ];
          system.configurationRevision = self.rev or self.dirtyRev or null;
        }
      ];
    in
    {
      darwinConfigurations = {
        kage = nix-darwin.lib.darwinSystem {
          modules = commonModules ++ [
            {
              networking.hostName = "kage";
              system.primaryUser = "kon";
              # Declarative SSH access from the pubkeys repo. macOS sshd also
              # still honors ~/.ssh/authorized_keys (AuthorizedKeysFile),
              # so keys can be bootstrapped before this flake is applied.
              users.users.kon.openssh.authorizedKeys.keyFiles = [ "${pubkeys}/authorized_keys_strict" ];
            }
          ];
        };
      };
    };
}
