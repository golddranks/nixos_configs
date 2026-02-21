{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    nixd
    nil
    nixfmt-rfc-style
    ripgrep
    ripgrep-all
    nkf
    sd
    fd
    jq
    coreutils
    shellcheck
    tokei
    uv
    zstd
    tree
    pstree
    rustup
    nodejs
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.enable = false;
  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    stateVersion = 5;
    defaults = {
      CustomUserPreferences = {
        "com.apple.desktopservices".DSDontWriteNetworkStores = true;
      };
      finder = {
        AppleShowAllFiles = true;
        FXPreferredViewStyle = "Nlsv";
        AppleShowAllExtensions = true;
      };
      dock = {
        autohide = true;
        mru-spaces = false;
      };
      screencapture.location = "~/Pictures/screenshots";
      screensaver.askForPasswordDelay = 10;
    };
  };
}
