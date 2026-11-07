{ config, lib, pkgs, ... }:

let
  # The LAN's GUA /64 (mon's /root/recipes/set-lan-prefix moves it). It is in the
  # /llm/ allow list so that a LAN client which used the public address - or
  # typed the GUA - still counts as local. Update the two together.
  lanGua = "2405:1200:54b:4500::/64";
in
{
  imports =
    [
      ../common.nix
      ./hardware-configuration.nix
    ];

  networking.hostName = "bead";

  time.timeZone = "Asia/Tokyo";

  # Upgrade from this repo's flake (versions pinned by flake.lock) instead of a
  # channel. common.nix sets a channel, and the two options are mutually exclusive.
  system.autoUpgrade = {
    flake = "/home/kon/nixos_configs#bead";
    channel = lib.mkForce null;
    # --upgrade only refreshes root's channels, which flake builds don't use.
    upgrade = false;
  };

  # Mainline instead of nixos-hardware's linux_rpi4, which isn't in the binary
  # cache. Its ~62 MiB Image needs u-boot >= 2025.07 in /boot/efi (older ones
  # fit only ~36 MiB). The SSD uses uas, which is a module in this kernel.
  boot.kernelPackages = pkgs.linuxPackages;
  boot.initrd.availableKernelModules = [ "uas" ];

  # The model and a nix evaluation (autoUpgrade) compete for little RAM.
  zramSwap.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kon = {
    isNormalUser = true;
    description = "Pyry Kontio";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # AVAHI: Publish this server and its address on the network (bead.local)
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    extraServiceFiles = {
      ssh = "${pkgs.avahi}/etc/avahi/services/ssh.service";
      sftp = "${pkgs.avahi}/etc/avahi/services/sftp-ssh.service";
    };
  };

  # llama.cpp: the model server, on loopback only. nginx terminates TLS and is
  # the only way in - https://bead.drasa.eu/llm/ - so the port is never opened
  # on any LAN-facing address.
  services.llama-cpp = {
    enable = true;
    host = "::1";
    # Qwen3.8 starts at 27B, far too big for a Pi 4. Qwen3.5 is the newest Qwen
    # with small models, and the architecture Qwen3.8 is built on.
    model = pkgs.fetchurl {
      url = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/e87f176479d0855a907a41277aca2f8ee7a09523/Qwen3.5-4B-Q4_K_M.gguf";
      hash = "sha256-AP55hv9fa0Y+YkVYIRRgSdtvkxNgOTinCADR+2nvEaQ=";
    };
    # The defaults are sized for big GPU boxes. These keep llama-server at
    # ~3 GiB of this 4 GB Pi's 3.7 GiB usable.
    extraFlags = [
      "--alias" "qwen3.5-4b"
      "--ctx-size" "4096"     # default: the model's full 262144
      "--ubatch-size" "256"   # smaller compute buffer; default: 512
      "--parallel" "1"        # default: 4 slots
      "--ctx-checkpoints" "2" # default: 32 per slot, ~53 MiB each for this model
      "--cache-ram" "0"       # no cross-conversation prompt cache; default: 8 GiB
      "--reasoning" "off"     # it thinks by default; that takes minutes here
      # Qwen's recommended non-thinking sampling; the GGUF doesn't carry it.
      "--temp" "0.7" "--top-p" "0.8" "--top-k" "20" "--min-p" "0" "--presence-penalty" "1.5"
      # Served under /llm so nginx can hand it one subdirectory of the vhost.
      "--api-prefix" "/llm"
      "--api-key-file" "/var/lib/llama-cpp/api-key"
    ];
  };

  # The API key is generated on first start; read it back with
  # `sudo cat /var/lib/llama-cpp/api-key`. Nothing secret lives in this file or
  # in the nix store - the module's StateDirectory leaves the service's own user
  # as the only writer.
  systemd.services.llama-cpp.preStart = ''
    if [ ! -s /var/lib/llama-cpp/api-key ]; then
      umask 077
      ${pkgs.openssl}/bin/openssl rand -hex 32 > /var/lib/llama-cpp/api-key
    fi
  '';

  # TLS front-end. `/` is public; `/llm/` answers only sources on the LAN's own
  # address ranges, which is what makes the key-only LLM a LAN service even
  # though the vhost is reachable from the internet.
  services.nginx = {
    enable = true;
    virtualHosts."bead.drasa.eu" = {
      enableACME = true;
      forceSSL = true;
      default = true;
      locations."/" = {
        root = pkgs.writeTextDir "index.html" "Welcome to bead.";
      };
      locations."/llm/" = {
        proxyPass = "http://[::1]:${toString config.services.llama-cpp.port}";
        extraConfig = ''
          allow fc00::/7;
          allow fe80::/10;
          allow ${lanGua};
          deny all;

          proxy_buffering off;
          proxy_read_timeout 3600;
        '';
      };
    };
  };

  # 80 carries the ACME challenge and the redirect; 443 the vhost itself.
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
