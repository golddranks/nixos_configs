# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=45
  '';

  networking.hostName = "nagi"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp8s0.useDHCP = true;

# Disable IPv6 privacy protection because this is a server and we want a static-ish address
  networking.interfaces.enp8s0.tempAddress = "disabled";

# Enable RA for IPv6 tokens to work
  services.udev.extraRules = "
    ACTION==\"add\", SUBSYSTEM==\"net\", RUN+=\"${pkgs.procps}/bin/sysctl net.ipv6.conf.enp8s0.accept_ra=1\"
    ACTION==\"add\", SUBSYSTEM==\"net\", RUN+=\"${pkgs.iproute}/bin/ip token set '::10' dev enp8s0\"
    ";


#  networking.interfaces.br0.useDHCP = true;
#  networking.bridges = { "br0" = { "interfaces" = ["enp8s0" "wlp6s0"]; }; };

#  networking.wireless.enable = true;
#  networking.wireless.networks = { "Skeletor 5Ghz" = { psk = "35732778"; }; };
#  networking.interfaces.wlp6s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  hardware.bluetooth.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim pstree tree lsof rsync pciutils ripgrep fd gcc
  ];

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.challengeResponseAuthentication = false;
  services.openssh.permitRootLogin = "no";

  services.fail2ban.enable = true;

  # Publish this server and its address on the network
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    extraServiceFiles = {
      ssh = "${pkgs.avahi}/etc/avahi/services/ssh.service";
      sftp = "${pkgs.avahi}/etc/avahi/services/sftp-ssh.service";
    };
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."nagi.drasa.eu" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www/nagi.drasa.eu";
  };

  security.acme.acceptTerms = true;
  security.acme.email = "pyry.kontio@drasa.eu";

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Enable CUPS to print documents.
  # services.printing.enable = true;

/*
  services.hostapd = {
    enable = true;
    ssid = "Skeletor 2.5Ghz";
    wpaPassphrase = "35732778";
    interface = "wlp6s0";
    hwMode = "g";
    channel = 6;
    # countryCode = "JP"; # enable this when on NixOS 20.09
    extraConfig = ''
      country_code=JP
      # required for 802.11n https://wiki.gentoo.org/wiki/Hostapd#802.11b.2Fg.2Fn_with_WPA2-PSK_and_CCMP
      rsn_pairwise=CCMP
      ieee80211n=1
      wmm_enabled=1
      '';
  };
*/

 services.udev.packages = [ pkgs.crda ];

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  virtualisation.docker.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  users.users = {
    kon = {
      isNormalUser = true;
      description = "Pyry Kontio";
      extraGroups = [ "wheel" "networkmanager" "docker" ];
    };
    samba = {
      description = "Samba";
    };
  };

  nixpkgs.config.allowUnfree = true;
}
