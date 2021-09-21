# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = "poi"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=45
  '';

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;
  # Disable IPv6 privacy protection because this is a server and we want a static-ish address
  networking.interfaces.eth0.tempAddress = "disabled";
  networking.interfaces.wlan0.tempAddress = "disabled";

  # Enable RA for IPv6 tokens to work
  services.udev.extraRules = "
    ACTION==\"add\", SUBSYSTEM==\"net\", RUN+=\"${pkgs.procps}/bin/sysctl net.ipv6.conf.eth0.accept_ra=1\"
    ACTION==\"add\", SUBSYSTEM==\"net\", RUN+=\"${pkgs.iproute2}/bin/ip token set '::20' dev eth0\"
    ";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";


  system.autoUpgrade.enable = true;


  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kon = {
    isNormalUser = true;
    description = "Pyry Kontio";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim pstree tree lsof rsync pciutils ripgrep fd
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.challengeResponseAuthentication = false;
  services.openssh.permitRootLogin = "no";
  services.fail2ban.enable = true;

  # AVAHI: Publish this server and its address on the network
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

  # NGINX
  services.nginx.enable = true;
  services.nginx.virtualHosts."poi.drasa.eu" = {
      enableACME = true;
      forceSSL = true;
      default = true;
      root = "/srv/www/poi.drasa.eu";
  };
  services.nginx.appendHttpConfig = "charset UTF-8;";
  security.acme.acceptTerms = true;
  security.acme.email = "pyry.kontio@drasa.eu";

  # DOCKER
  virtualisation.docker.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?


  # Extra: dropbox user
  users.users.dropbox = {
    shell = "/bin/clear_env.sh";
    home = "/home";
    description = "An user for sending files via SCP/rsync";
    isSystemUser = true;
  };
  users.groups.dropbox.members = [ "dropbox" ];
  fileSystems."/".options = [ "usrjquota=aquota.user,jqfmt=vfsv1" ];
  systemd.mounts = [
    {
      where = "/chroot/dropbox/home";
      what = "/chroot/dropbox_home";
      options = "rw,noexec,nosuid,nodev,bind";
      wantedBy = [ "local-fs.target" ];
    }
  ];
  security.pam.loginLimits =
    let db_limit = item: value: {
      "domain" = "dropbox";
      "item" = item;
      "type" = "hard";
      "value" = value;
    };
    in
    [
      (db_limit "nproc" "50")
      (db_limit "nofile" "50")
      (db_limit "priority" "10")
      (db_limit "nice" "10")
      (db_limit "cpu" "60")
      (db_limit "maxlogins" "5")
      (db_limit "fsize" "5242880")
      (db_limit "core" "0")
      (db_limit "as" "51200")
    ];

  systemd.slices.user-1002.sliceConfig.MemoryMax = "150M";
  systemd.slices.user-1002.sliceConfig.CPUQuota = "160%";
  services.openssh.extraConfig = ''
    PrintLastLog no
    Match User dropbox
      PasswordAuthentication yes
      ChrootDirectory /chroot/dropbox
      AllowTCPForwarding no
      X11Forwarding no
      AuthorizedKeysFile /chroot/dropbox_authorized_keys
      Banner /chroot/dropbox_banner.txt
  '';
  # setting passwordAuthentication to false disables PAM's Unix auth,
  # which prevents the dropbox special case; we force PAM to allow Unix auth
  security.pam.services.sshd.unixAuth = pkgs.lib.mkForce true;
}

