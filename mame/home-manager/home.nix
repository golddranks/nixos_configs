{ config, pkgs, ... }:

{
  home.username = "kon";
  home.homeDirectory = "/home/kon";
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.killall
  ];

  home.file = {
  };

  home.sessionVariables = {
  };

  systemd.user.services.killall_vscode_node = {
    Unit.Description = "Kill all CPU hog remote VS Code node processes at night";
    Service.ExecStart = "/home/kon/.nix-profile/bin/killall node";
  };
  systemd.user.timers.killall_vscode_node = {
    Timer.OnCalendar = "*-*-* 3,4,5:30";
    Timer.Unit = "killall_vscode_node.service";
    Install.WantedBy = [ "timers.target" ];
  };
}
