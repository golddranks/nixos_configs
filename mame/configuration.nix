{ config, pkgs, ... }:
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
    year=$(date +%Y)
    cd "/srv/www/webshare.drasa.eu"
    mkdir -p archive/$year
    mkdir -p archive/protected/$year
    find * -maxdepth 0 -mtime +14 \! -path protected \! -path archive -exec mv {} archive/$year/ \;
    find protected/* -maxdepth 0 -mtime +14 \! -path protected \! -path archive -exec mv {} archive/protected/$year/ \;
  '';
  unstable = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  }) {
    system = pkgs.system;
  };
in {
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ../common.nix
    ];

  networking.hostName = "mame";

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

  fileSystems."/etc/secrets" = {
    device = "/mnt/Avaruus/@varmuus/mame_state/secrets";
    options = [ "bind" "nofail" ];
  };

  fileSystems."/etc/nix_state" = {
    device = "/mnt/Avaruus/@varmuus/mame_state/nix_state";
    options = [ "bind" "nofail" ];
  };

  time.timeZone = "Asia/Tokyo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  # Disable IPv6 privacy protection because this is a server and we want a static-ish address
  networking.tempAddresses = "disabled";
  networking.dhcpcd.extraConfig = "slaac token ::10";

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
    settings = let share = p: {
          path = p;
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "samba";
          "force group" = "users";
      }; in {
      global = {
        # Performance / limits
        "max open files" = 131072;
        "dfree command" = "${dfree_script}/bin/dfree";
        "server multi channel support" = "yes";
        "aio read size" = 1048576;
        "aio write size" = 1048576;
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
        "use sendfile" = "yes";

        # Protocol
        "server min protocol" = "SMB3_11";
        "client min protocol" = "SMB3_11";
        "smb encrypt" = "desired";
        "ntlm auth" = "disabled";
        "lanman auth" = "no";

        # Apple / macOS interoperability
        "vfs objects" = "fruit streams_xattr";
        "fruit:model" = "MacSamba";
        "fruit:metadata" = "stream";
        "fruit:posix_rename" = "yes";
        "fruit:zero_file_id" = "yes";
        "fruit:nfs_aces" = "no";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";

        # Identity
        "workgroup" = "WORKGROUP";
        "server string" = "mame";
        "netbios name" = "mame";

        # Security / guests
        "security" = "user";
        "map to guest" = "never";
      };
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
  services.nginx = {
    enable = true;
    appendHttpConfig = "charset UTF-8;";
    upstreams.vaultwarden.servers."127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}" = { };
    virtualHosts = {
      "mame.drasa.eu" = {
        enableACME = true;
        forceSSL = true;
        default = true;
        root = pkgs.writeTextDir "index.html" ''Hello, World! From: まめ'';
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

  systemd.services.archive_webshare.script = "${archive_script}/bin/archive.sh";
  systemd.timers.archive_webshare = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*-*-* 3:00";
    timerConfig.Unit = "archive_webshare.service";
  };

  services.smartd.enable = true;

  systemd.services.vaultwarden.unitConfig.RequiresMountsFor = [
    "/etc/secrets"
    "/etc/nix_state"
  ];
  services.vaultwarden = {
    enable = true;
    package = unstable.vaultwarden;
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
    environmentFile = "/etc/secrets/vaultwarden_secrets.env";
  };

  services.syncthing = {
    enable = true;
    dataDir = "/mnt/Avaruus/@varmuus/Syncthing";
    openDefaultPorts = true;
  };

  systemd.services.syncthing.unitConfig = {
    "RequiresMountsFor" = "/mnt/Avaruus/@varmuus/Syncthing";
  };

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
