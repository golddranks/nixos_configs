{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    nixd
    nil
    nixfmt
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
    python314
    zstd
    tree
    pstree
    rustup
    nodejs
    magic-wormhole-rs
    gh
    dutree
    audacity
    ffmpeg
    deno
    texliveFull
    ghostscript
    librsvg
    bun
    # From the unstable channel (see the overlay in flake.nix).
    unstable.cargo-tarpaulin
    unstable.cargo-fuzz
    unstable.lima
    unstable.ollama
    unstable.llama-cpp
    unstable.claude-code
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
