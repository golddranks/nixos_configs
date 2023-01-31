# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let dfree = pkgs.writeShellScriptBin "dfree" ''
  # The MacOS and Windows SMB clients just check the free space of the root folder, whith doesn't take into account
  # the free space in the mounted folders inside, so we are manually calculating the free space as the sum of those.
  if [ "$1" = '.' -a "$(pwd)" = "/srv/samba/Filesaari" ]; then
    (
      ${pkgs.coreutils}/bin/df /mnt/Valtavuus | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $2" "$4}'
      ${pkgs.coreutils}/bin/df /mnt/Avaruus | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $2" "$4}'
    ) | ${pkgs.gawk}/bin/awk '{i = i + $1}{j = j + $2} END {printf "%d %d \n", i, j}'
  else
    ${pkgs.coreutils}/bin/df "$1" | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $2" "$4}'
  fi
''; in
{
  nix = {
    gc.automatic = true;
  };

  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 30;

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

  fileSystems."/srv/samba/Filesaari/OmatKuvat" = {
    device = "/mnt/Avaruus/@varmuus/OmatKuvat";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Filesaari/OmatVideot" = {
    device = "/mnt/Avaruus/@varmuus/OmatVideot";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Filesaari/EditoidutVideot" = {
    device = "/mnt/Avaruus/@varmuus/EditoidutVideot";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Filesaari/Dokumentit" = {
    device = "/mnt/Avaruus/@varmuus/Dokumentit";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Filesaari/TutkimusPDF" = {
    device = "/mnt/Avaruus/@varmuus/TutkimusPDF";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Filesaari/MuutaArvokasta" = {
    device = "/mnt/Avaruus/@varmuus/MuutaArvokasta";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Filesaari/EiNiinArvokasta" = {
    device = "/mnt/Valtavuus/EiNiinArvokasta";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Filesaari/Musiikki" = {
    device = "/mnt/Avaruus/@varmuus/Musiikki";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/KonOnePlus" = {
    device = "/mnt/Avaruus/@varmuus/Syncthing/KonOnePlus";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Filesaari/Anime" = {
    device = "/mnt/Valtavuus/Video/animu";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/Valtavuus" = {
    device = "/mnt/Valtavuus";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/samba/WebShare" = {
    device = "/mnt/Valtavuus/WebShare";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/srv/www/webshare.drasa.eu" = {
    device = "/mnt/Valtavuus/WebShare";
    options = [ "bind" "nofail" ];
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
      isSystemUser = true;
      group = "samba";
    };
  };

  users.groups.samba = {};

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment.systemPackages =
    with pkgs;
    [
      wget vim pstree tree lsof rsync pciutils ripgrep fd dfree git
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
  services.openssh.kbdInteractiveAuthentication = false;
  services.openssh.permitRootLogin = "no";
  services.fail2ban.enable = true;

  # Enable Windows 10 to find the samba shares:
  services.samba-wsdd.enable = true;

  # Remember to set `defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE` on MacOS to speed up samba!
  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      max open files = 131072
      dfree command = "'' + dfree + ''/bin/dfree"
      server min protocol = SMB3_00
      vfs objects = fruit streams_xattr
      fruit:metadata = stream
      fruit:veto_appledouble = no
      fruit:wipe_intentionally_left_blank_rfork = yes
      fruit:delete_empty_adfiles = yes
      workgroup = WORKGROUP
      server string = mame
      netbios name = mame
      security = user
      guest account = nobody
      map to guest = bad user
      # These might affect version compatibility?!
      use sendfile = yes
    '';
    shares = let share = p: {
          path = p;
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "samba";
          "force group" = "users";
      }; in {
      KonOnePlus = {
        path = "/srv/samba/KonOnePlus";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "no";
        "valid users" = "kon";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "samba";
        "force group" = "users";
      };
      Filesaari = share "/srv/samba/Filesaari";
      Valtavuus = share "/srv/samba/Valtavuus";
      WebShare = share "/srv/samba/WebShare";
    };
  };

  # samba open file ulimit (the default is 16384, which sometimes isn't enough)
  systemd.services.samba-smbd.serviceConfig.LimitNOFILE = pkgs.lib.mkForce 131072;

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
      default = true;
      root = "/srv/www/mame.drasa.eu";
    };
    "webshare.drasa.eu" = let
        protected = builtins.toFile "protected.html" "This is a protected folder. A password is required, and the file index is not shown.";
        archive = builtins.toFile "archive.html" "This is an archive folder. The file index is not shown.";
      in {
      root = "/srv/www/webshare.drasa.eu";
      enableACME = true;
      forceSSL = true;
      locations = {
        "/" = {
          extraConfig = "autoindex on;";
        };
        "/archive/" = {
          tryFiles = "$uri /archive.html";
        };
        "/archive/protected" = {
          tryFiles = "$uri /protected.html";
          basicAuthFile = "/var/lib/nginx/secrets/webshare.drasa.eu_protected_password";
        };
        "/protected/" = {
          tryFiles = "$uri /protected.html";
          basicAuthFile = "/var/lib/nginx/secrets/webshare.drasa.eu_protected_password";
        };
        "=/protected.html".alias = protected;
        "=/archive.html".alias = archive;
      };
    };
    "bitwarden.drasa.eu" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:8080";
    };
    "syncthing.drasa.eu" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:8384";
    };
  };
  services.nginx.appendHttpConfig = "charset UTF-8;";

  services.cron =
  let
    script = pkgs.writeShellScriptBin "archive.sh" ''
      year=$(date +%Y)
      cd "/srv/www/webshare.drasa.eu"
      mkdir -p archive/$year
      mkdir -p archive/protected/$year
      find * -maxdepth 0 -mtime +14 \! -path protected \! -path archive -exec mv {} archive/$year/ \;
      find protected/* -maxdepth 0 -mtime +14 \! -path protected \! -path archive -exec mv {} archive/protected/$year/ \;
    '';
  in
  {
    enable = true;
    systemCronJobs = [ "0 3 * * * root ${script}/bin/archive.sh" ];
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "pyry.kontio@drasa.eu";

  services.vaultwarden = {
    enable = true;
    backupDir = "/srv/bitwarden-backup";
    config = {
      domain = "https://bitwarden.drasa.eu:8080";
      signupsAllowed = true;
      rocketPort = 8080;
      rocketLog = "critical";
    };
  };

  services.syncthing = {
    enable = true;
    dataDir = "/mnt/Avaruus/@varmuus/Syncthing";
    openDefaultPorts = true;
  };

  systemd.services.syncthing.unitConfig = {
    "RequiresMountsFor" = "/mnt/Avaruus/@varmuus/Syncthing";
  };

  services.iperf3.enable = true;
  services.iperf3.openFirewall = true;

  # DOCKER
  virtualisation.docker.enable = true;

  # Open ports in the firewall.
  # 445, 139, 137, 138: samba, netbios names
  # 5357, 3702: Web Service Discovery for Windows 10 & Samba
  networking.firewall.allowedTCPPorts = [ 445 139 80 443 5357 ];
  networking.firewall.allowedUDPPorts = [ 137 138 3702 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}

