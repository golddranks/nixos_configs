{ pkgs, ... }:
let
  pull_nix_config_script = ''
    git -C /home/kon/nixos_configs fetch origin main
    git -C /home/kon/nixos_configs rebase origin/main main || \
      git -C /home/kon/nixos_configs rebase --abort
  '';
in {
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 21d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  system.autoUpgrade.enable = true;

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
  services.fail2ban.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  systemd.services.pull_nix_config = {
    path = [ pkgs.git pkgs.openssh ];
    serviceConfig.User = "kon";
    script = pull_nix_config_script;
  };
  systemd.timers.pull_nix_config = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*-*-* 4:17";
    timerConfig.Unit = "pull_nix_config.service";
  };

  environment.systemPackages =
    with pkgs;
    [
      wget vim pstree tree lsof rsync pciutils ripgrep fd git socat dig tcpdump inetutils smartmontools
    ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "pyry.kontio@drasa.eu";

}
