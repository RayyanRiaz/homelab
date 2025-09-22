{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    promptInit = ''
      # Simple prompt
      PROMPT='%n@%m:%~%# '
    '';
    shellAliases = {
      ll = "ls -l";
    };
  };
}