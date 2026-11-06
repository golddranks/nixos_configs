{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../common.nix
    ];

  networking.hostName = "hato";

  # Upgrade from this repo's flake (versions pinned by flake.lock) instead of a
  # channel. common.nix sets a channel, and the two options are mutually exclusive.
  system.autoUpgrade = {
    flake = "/home/kon/nixos_configs#hato";
    channel = lib.mkForce null;
    # --upgrade only refreshes root's channels, which flake builds don't use.
    upgrade = false;
  };

  # 2 GB RAM, no swap: evaluating the system config can OOM without this.
  zramSwap.enable = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  time.timeZone = "Europe/Helsinki";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    kon = {
      isNormalUser = true;
      description = "Pyry Kontio";
      extraGroups = [ "wheel" "networkmanager" ];
    };
  };

  # NGINX
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "ganba.re" = {
        enableACME = true;
        forceSSL = true;
        default = true;
        root = "/srv/nginx";
      };
      "japania.ganba.re" = {
        enableACME = true;
        forceSSL = true;
        root = "/srv/japania.ganba.re";
      };
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  # To make VS Code (SSH remote) work
  programs.nix-ld.enable = true;
  services.openssh.extraConfig = ''
    AcceptEnv is_vscode
  '';
}
