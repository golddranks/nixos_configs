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

  # macOS starts ssh-agent empty at every login. git's SSH signing doesn't
  # respect config's AddKeysToAgent, so load the keychain manually.
  launchd.agents.ssh-add = {
    script = ''
      output=$(/usr/bin/ssh-add --apple-load-keychain 2>&1) && status=0 || status=$?
      /usr/bin/logger -t org.nixos.ssh-add "Keychain load exited $status: $output"
      exit "$status"
    '';
    serviceConfig.RunAtLoad = true;
  };

  # Leading-space commands must not reach the shared history file
  programs.zsh.interactiveShellInit = "setopt HIST_IGNORE_SPACE";

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
