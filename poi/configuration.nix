{ config, pkgs, ... }:

{
  imports =
    [
      ../common.nix
      ./hardware-configuration.nix
    ];

  networking.hostName = "poi";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

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

  system.autoUpgrade = {
    enable = true;
    flake = "/home/kon/nixos_configs/poi/";
    flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kon = {
    isNormalUser = true;
    description = "Pyry Kontio";
    extraGroups = [ "wheel" "networkmanager" ];
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

  # services.checkup = {
  #   enable = true;
  #   every = "30s";
  #   checkers = [
  #     {
  #       type = "http";
  #       endpoint_name = "Syncthing HTTP";
  #       endpoint_url = "https://syncthing.drasa.eu";
  #       up_status = 401;
  #     }
  #     {
  #       type = "http";
  #       endpoint_name = "Webshare HTTP";
  #       endpoint_url = "https://webshare.drasa.eu";
  #     }
  #     {
  #       type = "http";
  #       endpoint_name = "Bitwarden HTTP";
  #       endpoint_url = "https://bitwarden.drasa.eu";
  #     }
  #     {
  #       type = "http";
  #       endpoint_name = "Mame HTTP";
  #       endpoint_url = "https://mame.drasa.eu";
  #     }
  #     {
  #       type = "http";
  #       endpoint_name = "Poi HTTP";
  #       endpoint_url = "https://poi.drasa.eu";
  #     }
  #     {
  #       type = "http";
  #       endpoint_name = "Saunoja";
  #       endpoint_url = "https://saunoja.jp";
  #       attempts = 2;
  #     }
  #     {
  #       type = "http";
  #       endpoint_name = "Saunoja Analytics";
  #       endpoint_url = "https://analytics.saunoja.jp";
  #       attempts = 2;
  #     }
  #     {
  #       type = "http";
  #       endpoint_name = "Noora Kirsikka";
  #       endpoint_url = "https://www.noorakirsikka.fi";
  #     }
  #     {
  #       type = "http";
  #       endpoint_name = "Accent Ganbare";
  #       endpoint_url = "https://accent.ganba.re/login";
  #     }
  #     {
  #       type = "tcp";
  #       endpoint_name = "Poi SSH";
  #       endpoint_url = "poi.drasa.eu:22";
  #     }
  #     {
  #       type = "tcp";
  #       endpoint_name = "Mame SSH";
  #       endpoint_url = "mame.drasa.eu:22";
  #     }
  #     {
  #       type = "tcp";
  #       endpoint_name = "Poi SSH (IPv4)";
  #       endpoint_url = "drasa.eu:999";
  #     }
  #     {
  #       type = "tcp";
  #       endpoint_name = "Syncthing TCP (IPv6)";
  #       endpoint_url = "syncthing.drasa.eu:22000";
  #     }
  #     {
  #       type = "tcp";
  #       endpoint_name = "Syncthing TCP (IPv4)";
  #       endpoint_url = "drasa.eu:22000";
  #     }
  #   ];
  #   notifiers = [];
  #   statusPage = "0.0.0.0:3000";
  # };
  # users.users.checkup.group = "checkup";
  # users.groups.checkup = {};

  # iperf3 is a network throughput tester
  services.iperf3.enable = true;
  services.iperf3.openFirewall = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 3000 ];
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
    group = "dropbox";
  };
  users.groups.dropbox = {};
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

    AcceptEnv is_vscode
  '';
  # setting passwordAuthentication to false disables PAM's Unix auth,
  # which prevents the dropbox special case; we force PAM to allow Unix auth
  security.pam.services.sshd.unixAuth = pkgs.lib.mkForce true;


  # To make VS Code (SSH remote) work
  programs.nix-ld.enable = true;
  # defined above
  #services.openssh.extraConfig = ''
  #  AcceptEnv is_vscode
  #'';
}

