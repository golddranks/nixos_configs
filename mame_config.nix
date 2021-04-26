# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  fileSystems."/mnt/Avaruus" =
    { device = "/dev/disk/by-uuid/3d293e93-b66c-462f-8451-84c2c5f25e7f";
      fsType = "btrfs";
      options = [ "nofail" ];
    };

  fileSystems."/mnt/Valtavuus" =
    { device = "/dev/disk/by-uuid/a810a776-7a19-4cfe-b406-401554027879";
      fsType = "ext4";
      options = [ "nofail" ];
    };

  fileSystems."/srv/samba/Kuvat" = {
    device = "/mnt/Avaruus/@varmuus/Kuvi";
    options = [ "bind" ];
  };

  fileSystems."/srv/samba/Musiikki" = {
    device = "/mnt/Avaruus/@varmuus/Musiikki";
    options = [ "bind" ];
  };

  fileSystems."/srv/samba/Downloads" = {
    device = "/mnt/Avaruus/@varmuus/Downloads";
    options = [ "bind" ];
  };

  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=45
  '';

  networking.hostName = "mame"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  # Disable IPv6 privacy protection because this is a server and we want a static-ish address
  networking.interfaces.eno1.tempAddress = "disabled";

  # Enable RA for IPv6 tokens to work
  services.udev.extraRules = "
    ACTION==\"add\", SUBSYSTEM==\"net\", RUN+=\"${pkgs.procps}/bin/sysctl net.ipv6.conf.eno1.accept_ra=1\"
    ACTION==\"add\", SUBSYSTEM==\"net\", RUN+=\"${pkgs.iproute}/bin/ip token set '::10' dev eno1\"
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim pstree tree lsof rsync ripgrep fd
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

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = mame
      netbios name = mame
      security = user
      guest account = nobody
      map to guest = bad user
      # These might affect version compatibility?!
      use sendfile = yes
      server min protocol = SMB3_00
    '';
    shares = {
      Filesaari = {
        path = "/srv/samba";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "samba";
        "force group" = "users";
      };
    };
  };
  
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
      smb = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
     '';
    };
  };

  # NGINX
  services.nginx.enable = true;
  services.nginx.virtualHosts = {
    "mame.drasa.eu" = {
      enableACME = true;
      forceSSL = true;
      root = "/srv/www/mame.drasa.eu";
    };
    "bitwarden.drasa.eu" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:8080";
      };
    };
  };
  services.nginx.appendHttpConfig = "charset UTF-8;";
  security.acme.acceptTerms = true;
  security.acme.email = "pyry.kontio@drasa.eu";

  services.bitwarden_rs = {
    enable = true;
    backupDir = "/srv/bitwarden-backup";
    config = {
      domain = "https://bitwarden.drasa.eu:8080";
      signupsAllowed = true;
      rocketPort = 8080;
      rocketLog = "critical";
    };
  };


  # DOCKER
  virtualisation.docker.enable = true;

  # Open ports in the firewall.
  # 445, 139, 137, 138: samba, netbios names
  networking.firewall.allowedTCPPorts = [ 445 139 80 443 ];
  networking.firewall.allowedUDPPorts = [ 137 138 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}

