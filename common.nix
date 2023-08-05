{ pkgs, ... }:
let
  pull_nix_config_script = ''
    git -C /home/kon/nixos_configs fetch origin main
    git -C /home/kon/nixos_configs rebase origin/main main || \
      git -C /home/kon/nixos_configs rebase --abort
  '';
in {
  systemd.services.pull_nix_config = {
    path = [ pkgs.git pkgs.openssh ];
    serviceConfig.User = "kon";
    script = pull_nix_config_script;
  };
}
