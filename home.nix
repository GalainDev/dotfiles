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
  home.packages = with pkgs; [ ];

  home.sessionVariables.EDITOR = "nvim";

  # NOTE: deliberately NOT managing zsh/shell yet — your existing ~/.zshrc
  # (nvm etc.) stays untouched. Adopting programs.zsh + starship is a good
  # later exercise once you're comfortable with the rebuild loop.

  # ── Config symlinks (edit-in-place; the repo is the source of truth) ──────
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
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
