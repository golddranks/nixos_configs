{ config, pkgs, ... }:
let
  # Dvorak-QWERTY-Suomi's input source ID, derived by macOS; see LEARNINGS.md.
  dvorakSuomi = "eu.drasa.keyboardlayout.dvorak_qwerty_suomi.keylayout.Dvorak–QWERTY⌘Suomi";
in
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
    python315
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
    jujutsu
    sops
    age
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

  # Copied, as an installer would; whether macOS follows a symlink into the
  # store here is untested. The store path is the directory because store
  # names can't hold the bundle's spaces and ⌘.
  system.activationScripts.postActivation.text = ''
    src="${./keyboard-layouts}/Dvorak – QWERTY ⌘ Suomi.bundle"
    dst="/Library/Keyboard Layouts/Dvorak – QWERTY ⌘ Suomi.bundle"
    if ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
      rm -rf "$dst"
      cp -R "$src" "$dst"
      chmod -R u+w "$dst"
    fi
  '';

  # The enabled keyboard layouts and input modes, exhaustively, and the one selected at login.
  # Runs in the login session (the input source API is per session) and at every login,
  # so changes made in System Settings don't stick.
  # Finnish (QWERTY) is for occasional QWERTY users.
  launchd.user.agents.input-sources = {
    script =
      let
        sources = {
          enabled = [
            dvorakSuomi
            "com.apple.keylayout.Finnish"
            "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese" # 日本語
          ];
          selected = dvorakSuomi;
        };
      in
      ''
        output=$(/usr/bin/osascript -l JavaScript ${./input-sources.js} ${pkgs.lib.escapeShellArg (builtins.toJSON sources)} 2>&1) && status=0 || status=$?
        /usr/bin/logger -t org.nixos.input-sources "exited $status: $output"
        exit "$status"
      '';
    serviceConfig.RunAtLoad = true;
  };

  # pull_nix_config from common.nix, as a user agent so it runs as kon
  # (nix-darwin loads launchd.agents as root). Only on main: this checkout is
  # worked in, and `rebase origin/main main || rebase --abort` would switch
  # branches or abort a rebase in progress.
  launchd.user.agents.pull_nix_config = {
    # Apple's ssh, as in a shell.
    path = [
      pkgs.git
      "/usr/bin"
    ];
    script = ''
      cd /Users/kon/repos/nixos_configs || exit
      git fetch origin main
      [ "$(git branch --show-current)" = main ] || exit 0
      git rebase --no-autostash origin/main || git rebase --abort
    '';
    serviceConfig.StartCalendarInterval = [
      {
        Hour = 4;
        Minute = 17;
      }
    ];
  };

  # Notifies when the running nixpkgs or Determinate Nix is older than the
  # newest release of it published 7+ days ago, when a newer NixOS release
  # is out, and when this one is past end of life. nixpkgs publishes by
  # nixos-channel-bot pushing the channel's branch, so its push times are
  # publication times. Determinate Nix is outside nix-darwin (nix.enable).
  launchd.user.agents.should_rebuild = {
    path = [ pkgs.jq ];
    script = "/bin/sh ${./should-rebuild.sh} ${config.system.nixpkgsRelease}";
    serviceConfig.StartCalendarInterval = [
      {
        Hour = 12;
        Minute = 0;
      }
    ];
  };

  # Leading-space commands must not reach the shared history file
  programs.zsh.interactiveShellInit = "setopt HIST_IGNORE_SPACE";

  system = {
    stateVersion = 5;
    defaults = {
      CustomUserPreferences = {
        "com.apple.desktopservices".DSDontWriteNetworkStores = true;
        # The layout Apple's Japanese IME reads keys through when typing kana.
        "com.apple.inputmethod.Kotoeri".JIMPrefRomajiKeyboardLayoutKey = dvorakSuomi;
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
