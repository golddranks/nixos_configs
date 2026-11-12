{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "bead";

  time.timeZone = "Asia/Tokyo";

  # SLAAC with the same ::bead suffix as its DHCPv6 lease, for the same
  # redundancy as cafe (see there). bead's ethernet is configured by the
  # generic catch-all unit, not a per-interface one.
  systemd.network.networks."99-ethernet-default-dhcp".ipv6AcceptRAConfig.Token = "::bead";

  # Mainline instead of the Raspberry Pi kernel (linux_rpi4), which isn't in the
  # binary cache. Its ~62 MiB Image needs u-boot >= 2025.07 in /boot/efi (older ones
  # fit only ~36 MiB).
  boot.kernelPackages = pkgs.linuxPackages;
  # The SSD's ASMedia bridge (174c:55aa) stalls under sustained I/O with uas on
  # this kernel, freezing everything that touches the disk. usb-storage is fine.
  boot.kernelParams = [ "usb-storage.quirks=174c:55aa:u" ];

  # The Pi-specific bits that used to come from nixos-hardware's raspberry-pi-4
  # module. u-boot (in /boot/efi) reads /boot/extlinux/extlinux.conf.
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };
  # The SSD hangs off the VL805 USB controller, which sits on PCIe and needs
  # its firmware loaded via the VideoCore before the root disk appears.
  boot.initrd.availableKernelModules = [
    "pcie_brcmstb"
    "reset-raspberrypi"
    "usb_storage"
  ];
  hardware.deviceTree.filter = "bcm2711-rpi-*.dtb";
  # 835 MB of linux-firmware, needed here only for the unused wifi and
  # Bluetooth. hardware-configuration.nix's not-detected.nix defaults it on.
  hardware.enableRedistributableFirmware = false;
  # ...so the wifi and Bluetooth drivers only fail and log about it, and wlan0
  # sits "configuring" in networkd forever. bead is wired-only.
  boot.blacklistedKernelModules = [
    "brcmfmac" # wifi; it's also what pulls in cfg80211 and its regulatory.db
    "hci_uart" # Bluetooth (the Pi's BT chip hangs off a UART)
  ];

  # The model and a nix evaluation (autoUpgrade) compete for little RAM.
  zramSwap.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.

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

  # The API key gating llm.drasa.eu (services.nginx below), encrypted in the
  # repo (../secrets/bead.json) and decrypted at activation using bead's own
  # SSH host key. Edit with: SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
  # sops edit secrets/bead.json
  sops.defaultSopsFile = ../secrets/bead.json;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  # DynamicUser has no stable uid/gid to own the secret, so it's granted
  # access via a real, static group instead (see SupplementaryGroups below).
  sops.secrets.llama_cpp_api_key = {
    group = "llama-cpp-secrets";
    mode = "0440";
  };
  users.groups.llama-cpp-secrets = { };

  # llama.cpp: the model server, on loopback only. nginx terminates TLS and is
  # the only way in - https://llm.drasa.eu/ - so the port is never opened on any
  # LAN-facing address.
  services.llama-cpp = {
    enable = true;
    host = "::1";
    # Quality over speed. Measured on this Pi 4: this 4B Q4_K_M (2.7 GB) does
    # 1.6 tok/s on a short prompt and 2.5 tok/s of prompt processing; the 2B
    # Q4_K_S (1.2 GB) did 4.0 and 7.2. Generation is memory-bandwidth-bound, so
    # the weights are what matter.
    model = pkgs.fetchurl {
      url = "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/e87f176479d0855a907a41277aca2f8ee7a09523/Qwen3.5-4B-Q4_K_M.gguf";
      hash = "sha256-AP55hv9fa0Y+YkVYIRRgSdtvkxNgOTinCADR+2nvEaQ=";
    };
    # The defaults are sized for big GPU boxes. These put llama-server at
    # ~3.2 GiB, which leaves the ~300 MiB the rest of bead needs - only because
    # it is stopped while nixos-upgrade evaluates (see below).
    extraFlags = [
      "--alias"
      "qwen3.5-4b"
      "--ctx-size"
      "8192" # 32 KiB of KV per token for this model
      "--ubatch-size"
      "256" # smaller compute buffer; default: 512
      "--parallel"
      "1" # default: 4 slots
      "--ctx-checkpoints"
      "2" # default: 32 per slot, ~50 MiB each for this model
      "--cache-ram"
      "0" # no cross-conversation prompt cache; default: 8 GiB
      "--reasoning"
      "off" # it thinks by default; that takes minutes here
      # Qwen's recommended non-thinking sampling; the GGUF doesn't carry it.
      "--temp"
      "0.7"
      "--top-p"
      "0.8"
      "--top-k"
      "20"
      "--min-p"
      "0"
      "--presence-penalty"
      "1.5"
      "--api-key-file"
      secrets.llama_cpp_api_key.path
      # bead has one job, so the weights are pinned rather than left evictable:
      # the kernel was already reclaiming them (workingset_refault_file was 56k
      # against a 3.7 GiB box), and every refault is a read from the USB disk,
      # where a device reset stalls a forward pass for 30 seconds.
      "--mlock"
    ];
  };

  systemd.services.llama-cpp.serviceConfig = {
    # `--mlock` is only as good as this rlimit, and systemd is the only thing that
    # can raise it: the service runs as a dynamic user with no CAP_IPC_LOCK.
    LimitMEMLOCK = "infinity";

    # Grants the dynamic user read access to the sops secret above via its
    # static group, since DynamicUser has no fixed uid/gid of its own to chown it to.
    SupplementaryGroups = [ "llama-cpp-secrets" ];
  };

  # Evaluating the system takes ~1 GB, which the pinned model leaves no room
  # for. postStop runs whether the upgrade succeeds or fails.
  systemd.services.nixos-upgrade = {
    preStart = "${pkgs.systemd}/bin/systemctl stop llama-cpp.service";
    postStop = "${pkgs.systemd}/bin/systemctl start llama-cpp.service";
  };

  # Ghost runs hourly at :17, so GC must not start near a quarter past: the
  # 03:15 default collided with the 03:17 run. 02:00 clears it by 17 minutes
  # and stays well clear of the 04:40 upgrade.
  nix.gc.dates = "02:00";

  # The nightly garbage collection reads the whole store through the same USB
  # link, with only ~500 MiB free while the model is pinned. Daily is deliberate
  # - a predictable rhythm beats one longer weekly outage - so the LLM is
  # stopped for a minute or two twice a night rather than OOM-killed.
  systemd.services.nix-gc = {
    preStart = "${pkgs.systemd}/bin/systemctl stop llama-cpp.service";
    postStop = "${pkgs.systemd}/bin/systemctl start llama-cpp.service";
  };

  # ~70 MiB of Python. sshd's own PerSourcePenalties throttles brute force, and
  # login is key-only.
  services.fail2ban.enable = lib.mkForce false;

  # TLS front-ends. `bead.drasa.eu` is public; `llm.drasa.eu` is open to the
  # internet too - the API key is the access control, not source address.
  services.nginx = {
    enable = true;
    virtualHosts = {
      "bead.drasa.eu" = {
        enableACME = true;
        forceSSL = true;
        default = true;
        locations."/" = {
          root = pkgs.writeTextDir "index.html" "Welcome to bead.";
        };
      };
      "llm.drasa.eu" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:${toString config.services.llama-cpp.port}";
          extraConfig = ''
            proxy_buffering off;
            proxy_read_timeout 3600;
          '';
        };
      };
    };
  };

  # 80 carries the ACME challenge and the redirect; 443 the vhost itself.
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
