{
  inputs = {};

  outputs = { self }: {
    nixosModules.default = ./configuration.nix;
  };
}
