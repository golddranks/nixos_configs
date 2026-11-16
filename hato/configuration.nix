{
  pkgs,
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

  # networkd resolves vpn.drasa.eu only once, when the link comes up - at boot
  # that's before resolved has any DNS servers, and it never notices the home
  # IP changing. The two interfaces used to each run the built-in
  # dynamicEndpointRefreshSeconds timer (touch its .netdev, networkctl
  # reload), both every 5 min from boot. networkctl reload makes a single
  # D-Bus Reload() call that networkd only runs one at a time; the second of
  # the two calls got -EBUSY ("Already reloading") and the unit was recorded
  # as failed. That happened repeatedly (observed many times on 2026-11-16).
  # wireguard-dynamic-refresh below replaces both with one shared service, so
  # there's only ever one reload per cycle.
  networking.wireguard.interfaces = {
    wg_skltr_lan = {
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

  # netdev config must be a real file, not a symlink into the store, so the
  # refresh service below can touch it (same as the built-in refresh option).
  environment.etc."systemd/network/40-wg_skltr_lan.netdev".mode = "0444";
  environment.etc."systemd/network/40-wg_skltr_jail.netdev".mode = "0444";

  systemd.services.wireguard-dynamic-refresh = {
    description = "Wireguard dynamic endpoint refresh (wg_skltr_lan, wg_skltr_jail)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [
      iproute2
      systemd
    ];
    script = ''
      touch /etc/systemd/network/40-wg_skltr_lan.netdev \
            /etc/systemd/network/40-wg_skltr_jail.netdev
      networkctl reload
    '';
  };
  systemd.timers.wireguard-dynamic-refresh = {
    partOf = [ "wireguard-dynamic-refresh.service" ];
    wantedBy = [ "timers.target" ];
    timerConfig.OnBootSec = 300;
    timerConfig.OnUnitInactiveSec = 300;
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
