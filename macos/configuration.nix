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

  # macOS starts ssh-agent empty at every login (Apple dropped keychain
  # auto-loading in Sierra). ssh_config's AddKeysToAgent only fires when ssh
  # itself runs, and git's SSH signing shells out to ssh-keygen -Y sign, which
  # reads no ssh_config and can only ask the agent — so without this the first
  # commit of a session dies with "Couldn't find key in agent?".
  # Redirected rather than StandardErrorPath: that key takes a literal path,
  # which would collapse every user's log onto one file.
  launchd.agents.ssh-add = {
    command = ''/usr/bin/ssh-add --apple-load-keychain 2>>"$HOME/Library/Logs/ssh-add.log"'';
    serviceConfig.RunAtLoad = true;
  };

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
