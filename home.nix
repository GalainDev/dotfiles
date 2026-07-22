{ config, pkgs, user, ... }:

let
  # All config symlinks resolve through ~/.dotfiles (created by bootstrap.sh /
  # rebuild.sh), which points at this repo. Editing files under home/ edits
  # your live config directly — no rebuild needed for symlinked files.
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";

  # Nix-managed user packages go here (Homebrew handles the rest for now).
  # Try it: add `pkgs.ripgrep` and run ./rebuild.sh — that's the whole loop.
  home.packages = with pkgs; [
    nerd-fonts.hack   # the font everything renders in (was a brew cask)
    glow              # render markdown in the terminal (styled, not raw text)
  ];
  fonts.fontconfig.enable = true;

  home.sessionVariables.EDITOR = "nvim";

  # ── Shell (home-manager owns ~/.zshrc now; the old one is backed up as
  #    ~/.zshrc.before-nix on first switch) ────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost-text suggestions from history
    syntaxHighlighting.enable = true;  # valid commands turn green as you type
    initContent = ''
      bindkey '^f' autosuggest-accept  # Ctrl+F accepts the ghost suggestion

      # ── ported verbatim from my pre-nix ~/.zshrc ──
      export PATH="$HOME/.local/bin:$PATH"   # native claude takes priority
      alias claude-a='claude --permission-mode auto'
      alias claude-dsp='claude --dangerously-skip-permissions'
      alias codex-dsp='codex --dangerously-bypass-approvals-and-sandbox'
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    '';
  };

  programs.zoxide = {
    enable = true;                # smart cd — was a manual eval in old zshrc
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;                # Ctrl+R fuzzy history, Ctrl+T fuzzy files
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;                # Kun's minimal prompt
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # ── Config symlinks (edit-in-place; the repo is the source of truth) ──────
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".config/aerospace".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/aerospace";
  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.tmux.conf";

  # Claude Code settings (auto mode, deny rules, sandbox config) live in the
  # repo — hardened once, versioned, portable.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # ── One AGENTS.md, every provider (harness Phase 1) ───────────────────────
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".gemini/GEMINI.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
