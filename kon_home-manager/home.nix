{ pkgs, ... }:

{
  home.username = "kon";
  home.homeDirectory = "/home/kon";
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.claude-claude-code
  ];

  home.file = {
  };

  home.sessionVariables = {
  };
}
