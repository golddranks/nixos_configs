{
  secrets,
  globals,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  networking.hostName = "hato";

  # 2 GB RAM, no swap: evaluating the system config can OOM without this.
  zramSwap.enable = true;

  # Secrets: encrypted in the repo (../secrets/hato.json), decrypted at
  # activation using hato's own existing SSH host key (no separate key to
  # manage). Edit with: SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops
  # edit secrets/hato.json
  sops.defaultSopsFile = ../secrets/hato.json;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.skeletor_lan_vpn_hato_privkey = { };
  sops.secrets.skeletor_jail_vpn_hato_privkey = { };

  # dynamicEndpointRefreshSeconds: networkd resolves vpn.drasa.eu only once,
  # when the link comes up - at boot that's before resolved has any DNS
  # servers, and it never notices the home IP changing. This re-resolves it
  # 5 min after boot and every 5 min after that.
  networking.wireguard.interfaces = {
    wg_skltr_lan = {
      dynamicEndpointRefreshSeconds = 300;
      ips = [ "${globals.skeletor_lan_ula}:1::3/64" ];
      privateKeyFile = secrets.skeletor_lan_vpn_hato_privkey.path;
      peers = [
        {
          publicKey = "C1/rDqqcbNsValOEMjZJ9RyujDEqMEVQaP08gIhAF24=";
          endpoint = "vpn.drasa.eu:51820";
          allowedIPs = [ "${globals.skeletor_lan_ula}::/48" ];
        }
      ];
    };
    wg_skltr_jail = {
      dynamicEndpointRefreshSeconds = 300;
      ips = [ "10.10.2.3/32" ];
      privateKeyFile = secrets.skeletor_jail_vpn_hato_privkey.path;
      peers = [
        {
          publicKey = "qWawJ7am19lpsHHaV83EoGSoHSTvFt4E0ENf0gJElTg=";
          endpoint = "vpn.drasa.eu:51821";
          allowedIPs = [
            "8.8.8.8/32"
            "10.10.1.1/32"
          ];
        }
      ];
    };
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
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
