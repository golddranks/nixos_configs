{
  pkgs,
  pubkeys,
  config,
  ...
}:
let
  pull_nix_config_script = ''
    git -C /home/kon/nixos_configs fetch origin main
    git -C /home/kon/nixos_configs rebase origin/main main || \
      git -C /home/kon/nixos_configs rebase --abort
  '';
in
{
  _module.args = {
    secrets = config.sops.secrets;
    globals = {
      # The home LAN's ULA prefix (skeletor is its internal name; mon is the
      # router). Exposed to every host's module via _module.args, so any host
      # that imports common.nix can use `skeletor_lan_ula` without extra wiring.
      skeletor_lan_ula = "fd42:6d6f:6e00";
    };
  };

  # systemd-networkd instead of the legacy scripted backend (dhcpcd). Hosts'
  # networking.interfaces.* and networking.wireguard.interfaces.* translate
  # automatically, and it brings systemd-resolved along for DHCP/RA-learned DNS.
  networking.useNetworkd = true;
  # Servers: no rotating privacy addresses, so outgoing connections come from
  # a stable, predictable address.
  networking.tempAddresses = "disabled";
  # DHCPv6 client ID derived from the MAC (00:03:00:01:<mac>) instead of
  # networkd's default, which hashes /etc/machine-id. mon's static leases
  # (::cafe, ::bead) are keyed on it, and this one survives a reinstall and
  # can be computed before a host first boots.
  systemd.network.config.dhcpV6Config.DUIDType = "link-layer";

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 21d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Builds from this repo on GitHub, so versions are pinned by flake.lock and
  # the nightly upgrade doesn't depend on the local checkout.
  system.autoUpgrade = {
    enable = true;
    flake = "github:golddranks/nixos_configs/main#${config.networking.hostName}";
    # --upgrade only refreshes root's channels, which flake builds don't use.
    upgrade = false;
  };

  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=45
  '';

  # The zone they're used from, not where they are (hato is in Helsinki).
  # Local-time timers (autoUpgrade, pull_nix_config, nix-gc) then fire at the
  # same moment on every host, and logs read alike.
  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_DK.UTF-8";
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";

  users.users = {
    kon = {
      isNormalUser = true;
      description = "Pyry Kontio";
      extraGroups = [ "wheel" ];
      # Declarative source of truth for kon's SSH access, pulled from the
      # pubkeys repo (the `pubkeys` flake input). NixOS still also honors
      # ~/.ssh/authorized_keys by default (AuthorizedKeysFile includes
      # %h/.ssh/...), so keys can be bootstrapped before this repo is ever
      # cloned onto a host.
      openssh.authorizedKeys.keyFiles = [ "${pubkeys}/authorized_keys_strict" ];
    };
    ghost = {
      isSystemUser = true;
      group = "nogroup";
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOn+7ho/vMdcej/4Hzuwq9hOamh25pc7rAIBNi+o4RWd ghost@mon"
      ];
    };
  };

  services.fail2ban.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  systemd.services.pull_nix_config = {
    path = [
      pkgs.git
      pkgs.openssh
    ];
    serviceConfig.User = "kon";
    script = pull_nix_config_script;
  };
  systemd.timers.pull_nix_config = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*-*-* 4:17";
    timerConfig.Unit = "pull_nix_config.service";
  };

  environment.systemPackages = with pkgs; [
    wget
    vim
    pstree
    tree
    lsof
    rsync
    pciutils
    ripgrep
    fd
    git
    socat
    dig
    tcpdump
    inetutils
    smartmontools
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "pyry.kontio@drasa.eu";

}
