{ config, pkgs, ... }:

{
  home.username = "rayyan";
  home.homeDirectory = "/home/rayyan";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # User-specific package
    htop
    neofetch
    bat
    fzf
    pkgs.oh-my-zsh
  ];

  # Configure zsh with home-manager
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      cat = "bat";
      ".." = "cd ..";
      "..." = "cd ../..";
      grep = "grep --color=auto";
    };
    
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      share = true;
    };

    initContent = ''
      # Custom zsh configuration
      setopt AUTO_CD              # Auto cd to directories
      setopt EXTENDED_GLOB         # Extended globbing
      setopt HIST_VERIFY          # Verify history expansions
      
      # Custom prompt
      autoload -U colors && colors
    '';

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "z" ];
    }; 
  };

  # Configure git (good to have for development)
  programs.git = {
    enable = true;
    userName = "rayyan";
    userEmail = "rayyanriaz2000@gmail.com";
    extraConfig = {
      init.defaultBranch = "master";
      core.editor = "vim";
    };
  };

}