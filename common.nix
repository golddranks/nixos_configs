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
    rebootWindow = {
      lower = "04:00";
      upper = "05:00";
    };
  };

  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=45
  '';

  i18n.defaultLocale = "en_DK.UTF-8";
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";

  # Declarative source of truth for kon's SSH access, pulled from the pubkeys
  # repo (the `pubkeys` flake input). NixOS still also honors
  # ~/.ssh/authorized_keys by default (AuthorizedKeysFile includes %h/.ssh/...),
  # so keys can be bootstrapped before this repo is ever cloned onto a host.
  users.users.kon.openssh.authorizedKeys.keyFiles = [ "${pubkeys}/authorized_keys_strict" ];

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
