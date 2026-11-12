{ config, pkgs, unstablePkgs, secrets, ... }:
let
  dfree_script = pkgs.writeShellScriptBin "dfree" ''
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
'';
  archive_script = pkgs.writeShellScriptBin "archive.sh" ''
    set -eu
    year=$(date +%Y)
    cd "/srv/www/share.drasa.eu"
    mkdir -p archive/$year
    mkdir -p archive/protected/$year
    # A glob expands to nothing when the directory is empty, which made
    # `find protected/*` fail and the timer go red every night; walk the
    # directories instead. Dotfiles stay put, like they did with the `*` glob.
    find . -mindepth 1 -maxdepth 1 -mtime +14 \! -name protected \! -name archive \! -name '.*' -exec mv {} archive/$year/ \;
    if [ -d protected ]; then
      find protected -mindepth 1 -maxdepth 1 -mtime +14 -exec mv {} archive/protected/$year/ \;
    fi
  '';
  bindMount = device: {
    inherit device;
    fsType = "auto";
    options = [ "bind" "nofail" ];
  };
in {
  imports =
    [
      ./hardware-configuration.nix
      ../common.nix
    ];

  networking.hostName = "cafe";

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

  fileSystems."/srv/samba/Filesaari/OmatKuvat" = bindMount "/mnt/Avaruus/@varmuus/OmatKuvat";
  fileSystems."/srv/samba/Filesaari/OmatVideot" = bindMount "/mnt/Avaruus/@varmuus/OmatVideot";
  fileSystems."/srv/samba/Filesaari/EditoidutVideot" = bindMount "/mnt/Avaruus/@varmuus/EditoidutVideot";
  fileSystems."/srv/samba/Filesaari/Dokumentit" = bindMount "/mnt/Avaruus/@varmuus/Dokumentit";
  fileSystems."/srv/samba/Filesaari/TutkimusPDF" = bindMount "/mnt/Avaruus/@varmuus/TutkimusPDF";
  fileSystems."/srv/samba/Filesaari/MuutaArvokasta" = bindMount "/mnt/Avaruus/@varmuus/MuutaArvokasta";
  fileSystems."/srv/samba/Filesaari/EiNiinArvokasta" = bindMount "/mnt/Valtavuus/EiNiinArvokasta";
  fileSystems."/srv/samba/Filesaari/Musiikki" = bindMount "/mnt/Avaruus/@varmuus/Musiikki";
  fileSystems."/srv/samba/Filesaari/Anime" = bindMount "/mnt/Valtavuus/Video/animu";
  fileSystems."/srv/samba/KonOnePlus" = bindMount "/mnt/Avaruus/@varmuus/Syncthing/KonOnePlus";
  fileSystems."/srv/samba/Valtavuus" = bindMount "/mnt/Valtavuus";
  fileSystems."/srv/samba/Share" = bindMount "/mnt/Valtavuus/Share";
  fileSystems."/srv/www/share.drasa.eu" = bindMount "/mnt/Valtavuus/Share";
  fileSystems."/etc/nix_state" = bindMount "/mnt/Avaruus/@varmuus/mame_state/nix_state";

  time.timeZone = "Asia/Tokyo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;

  # SLAAC alongside the static DHCPv6 lease (`hostid cafe`), for redundancy:
  # if mon reboots, its upstream GUA prefix can take a few seconds to arrive
  # from the ISP, and a DHCPv6 lease picked up in that window sits on a long
  # T1 before cafe tries again - tens of minutes of broken connectivity.
  # SLAAC re-addresses as soon as a corrected RA arrives, with no lease timer
  # to wait out. The static token keeps the SLAAC-derived address identical
  # to the DHCPv6 one (same ::cafe suffix), so the two paths converge on one
  # address instead of racing to two different ones, and disabling privacy
  # addresses keeps that the only SLAAC address on the interface.
  networking.tempAddresses = "disabled";
  networking.dhcpcd.extraConfig = "slaac token ::cafe";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    kon = {
      isNormalUser = true;
      description = "Pyry Kontio";
      extraGroups = [ "wheel" "networkmanager" ];
    };
    samba = {
      description = "Samba";
      isSystemUser = true;
      group = "samba";
    };
  };

  users.groups.samba = {};

  # To make VS Code (SSH remote) work
  programs.nix-ld.enable = true;
  services.openssh.extraConfig = ''
    AcceptEnv is_vscode
  '';

  # Remember to set `defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE` on MacOS to speed up samba!
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        # Global settings
        "max open files" = 131072; # see samba-smbd.serviceConfig.LimitNOFILE below
        "dfree command" = "${dfree_script}/bin/dfree";
        "server multi channel support" = "yes";
        "use sendfile" = "yes";
        "server min protocol" = "SMB3_11";
        "smb encrypt" = "desired";
        "workgroup" = "WORKGROUP";
        "server string" = "cafe";
        "log level" = "3";
        "map to guest" = "Bad User";
        "guest account" = "samba";

        # Apple / macOS interoperability
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:posix_rename" = "yes";
        "fruit:zero_file_id" = "yes";
        "fruit:nfs_aces" = "no";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";

        # Share defaults
        "guest ok" = "yes";
        "browseable" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "read only" = "no";
      };
      KonOnePlus = {
        "path" = "/srv/samba/KonOnePlus";
        "read only" = "yes";
        "valid users" = "kon";
      };
      Share = {
        "path" = "/srv/samba/Share";
        "guest ok" = "yes";
      };
      Filesaari = {
        "path" = "/srv/samba/Filesaari";
      };
      Valtavuus = {
        "path" = "/srv/samba/Valtavuus";
      };
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

  # Encrypted in the repo (../secrets/cafe.json), decrypted at activation using
  # cafe's own SSH host key. Edit with: SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
  # sops edit secrets/cafe.json
  sops.defaultSopsFile = ../secrets/cafe.json;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.vaultwarden_smtp_password = { };
  sops.secrets.vaultwarden_push_installation_key = { };
  # vaultwarden takes these as an env file, rendered at activation. Read by
  # systemd as root (EnvironmentFile=), so the default root:root 0400 works.
  sops.templates."vaultwarden.env".content = ''
    SMTP_PASSWORD=${config.sops.placeholder.vaultwarden_smtp_password}
    PUSH_INSTALLATION_KEY=${config.sops.placeholder.vaultwarden_push_installation_key}
  '';
  # Read by nginx workers on each request, not by the root master process.
  sops.secrets.share_htpasswd.owner = config.services.nginx.user;

  # NGINX
  services.nginx = {
    enable = true;
    appendHttpConfig = "charset UTF-8;";
    upstreams.vaultwarden.servers."127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}" = { };
    virtualHosts = {
      "cafe.drasa.eu" = {
        enableACME = true;
        forceSSL = true;
        default = true;
        root = pkgs.writeTextDir "index.html" ''Hello, World! From: カフェ'';
      };
      "share.drasa.eu" = let
          protected = builtins.toFile "protected.html" "This is a protected folder. A password is required, and the file index is not shown.";
          archive = builtins.toFile "archive.html" "This is an archive folder. The file index is not shown.";
        in {
        root = "/srv/www/share.drasa.eu";
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
            basicAuthFile = secrets.share_htpasswd.path;
          };
          "/protected/" = {
            tryFiles = "$uri /protected.html";
            basicAuthFile = secrets.share_htpasswd.path;
          };
          "=/protected.html".alias = protected;
          "=/archive.html".alias = archive;
        };
      };
      "bitwarden.drasa.eu" = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/".proxyPass = "http://vaultwarden";
          "= /notifications/anonymous-hub" = {
            proxyPass = "http://vaultwarden";
            proxyWebsockets = true;
          };
          "= /notifications/hub" = {
            proxyPass = "http://vaultwarden";
            proxyWebsockets = true;
          };
        };
      };
      "syncthing.drasa.eu" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://vaultwarden";
      };
    };
  };

  systemd.services.archive_share.script = "${archive_script}/bin/archive.sh";
  systemd.timers.archive_share = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*-*-* 3:00";
    timerConfig.Unit = "archive_share.service";
  };

  services.smartd.enable = true;

  systemd.services.vaultwarden.unitConfig.RequiresMountsFor = [ "/etc/nix_state" ];
  services.vaultwarden = {
    enable = true;
    package = unstablePkgs.vaultwarden;
    backupDir = "/etc/nix_state/bitwarden_backup";
    domain = "bitwarden.drasa.eu";
    config = {
      SIGNUPS_ALLOWED = true;
      SIGNUPS_VERIFY = true;
      ROCKET_PORT = 8080;
      SMTP_HOST = "smtp.eu.mailgun.org";
      SMTP_PORT = 465;
      SMTP_SSL = false;
      SMTP_FROM = "postmaster@bitwarden.drasa.eu";
      SMTP_FROM_NAME = "drasa.eu Bitwarden server";
      SMTP_SECURITY = "force_tls";
      SMTP_USERNAME = "postmaster@bitwarden.drasa.eu"; # SMTP password is in the env file
      PUSH_ENABLED = true; # PUSH_INSTALLATION_KEY is in the env file
      PUSH_INSTALLATION_ID = "30b8f8e0-81e4-40fc-b381-b3d100211585";
      PUSH_RELAY_URI = "https://api.bitwarden.eu";
      PUSH_IDENTITY_URI = "https://identity.bitwarden.eu";
    };
    environmentFile = config.sops.templates."vaultwarden.env".path;
  };

  services.syncthing = {
    enable = true;
    dataDir = "/mnt/Avaruus/@varmuus/Syncthing";
    openDefaultPorts = true;
  };

  systemd.services.syncthing.unitConfig.RequiresMountsFor = [
    "/mnt/Avaruus/@varmuus/Syncthing"
  ];

  # iperf3 is a network throughput tester
  services.iperf3.enable = true;
  services.iperf3.openFirewall = true;

  # Enable Windows 10 to find the samba shares:
  services.samba-wsdd = {
    enable = false;
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "25.11";

}
