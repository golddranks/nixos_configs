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
    cargo-tarpaulin
    cargo-fuzz
    ollama
    tokei
    audacity
    ffmpeg
    deno
    nodejs
    texliveFull
    uv
    ghostscript
    zstd
    tree
  ];

  networking.hostName = "kage";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.enable = false;
  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    primaryUser = "kon";
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
