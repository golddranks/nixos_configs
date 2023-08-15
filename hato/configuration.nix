{ config, pkgs, ... }:

{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ../common.nix
    ];

  networking.hostName = "hato";

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

        locations."/.well-known/host-meta" = {
          proxyPass = "http://unix:/run/mastodon-web/web.socket";
        };

        locations."/.well-known/webfinger" = {
          proxyPass = "http://unix:/run/mastodon-web/web.socket";
          proxyWebsockets = true;
        };
      };
      "japania.ganba.re" = {
        enableACME = true;
        forceSSL = true;
        root = "/srv/japania.ganba.re";
      };
      "social.ganba.re" = {
        root = "${pkgs.mastodon}/public/";
        forceSSL = true;
        enableACME = true;

        locations."/system/".alias = "/var/lib/mastodon/public-system/";

        locations."/" = {
          tryFiles = "$uri @proxy";
        };

        locations."@proxy" = {
          proxyPass = "http://unix:/run/mastodon-web/web.socket";
          proxyWebsockets = true;
        };

        locations."/api/v1/streaming/" = {
          proxyPass = "http://unix:/run/mastodon-streaming/streaming.socket";
          proxyWebsockets = true;
        };
      };
    };
  };

  # MASTODON
  services.mastodon = {
    enable = true;
    localDomain = "ganba.re";
    extraConfig = {
      WEB_DOMAIN = "social.ganba.re";
    };
    smtp = {
      host = "smtp.mailgun.org";
      port = 465;
      fromAddress = "mastodon@ganba.re";
      authenticate = true;
      user = "mastodon@ganba.re";
      passwordFile = "/var/lib/mastodon/secrets/smtp-password";
    };
  };

  users.groups.mastodon.members = [ "nginx" ];

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 51820 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.0.99.16/32" ];
    listenPort = 51820;
    privateKeyFile = "/home/kon/wg_privatekey";
    peers = [{
      name = "mon";
      publicKey = "9hQCYRWb+5tpcee3oLK/J+wFuAZpUo5KSFkxzAGQ4R0=";
      presharedKeyFile = "/home/kon/wg_drasa.eu_presharedkey";
      allowedIPs = [ "10.0.0.0/16" ];
      endpoint = "drasa.eu:51820";
      persistentKeepalive = 25;
    }];
  };

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
