{ pkgs, user, ... }:

{
  # Determinate Nix manages the nix daemon itself; nix-darwin must not.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;

  # System-level fonts land in "/Library/Fonts/Nix Fonts" — the mechanism macOS
  # actually sees. (home.packages fonts don't reach macOS font discovery.)
  fonts.packages = with pkgs; [ nerd-fonts.hack ];

  # macOS settings, declaratively. `defaults write` without the drift.
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat — makes held vim motions fly
      InitialKeyRepeat = 15;  # short delay before repeat kicks in
      AppleShowAllExtensions = true;
      # Kun also sets _HIHideMenuBar = true; add it here if you want the
      # menu bar to auto-hide. Left out as your first rebuild exercise.
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    trackpad.Clicking = true;              # tap to click
  };

  nix-homebrew = {
    enable = true;
    # Machine had Homebrew before nix: adopt the existing /opt/homebrew install.
    # Migration replaces the brew program itself but keeps every installed
    # package (Cellar/Caskroom untouched).
    autoMigrate = true;
    inherit user;
  };

  # Homebrew's repo is nix-managed (immutable), so `brew analytics off` can't
  # persist — disable analytics via the environment instead.
  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  homebrew = {
    enable = true;
    # AeroSpace ships from its developer's tap. Fresh machines must also run
    # `brew trust nikitabobko/tap` once (trust is machine-local, not declarable).
    taps = [ "nikitabobko/tap" ];
    # IMPORTANT: Kun uses cleanup = "zap", which UNINSTALLS anything not in
    # these lists on every switch. We start with "none" (never remove).
    # Once you trust the lists below are complete, flip to "uninstall" to get
    # fully declarative package management.
    onActivation.cleanup = "none";
    onActivation.autoUpdate = true;

    # Trimmed to only what this build actually uses (same rationale as casks
    # below). cleanup stays "none", so nothing already installed is removed —
    # this only affects what a NEW machine gets automatically.
    brews = [
      "bat"            # nicer `cat` — syntax highlighting, git-diff gutter
      "fd"             # faster `find`, gitignore-aware
      "fzf"            # wired into home.nix shell config (Ctrl+R/Ctrl+T)
      "gh"             # used throughout to create/manage this whole repo suite
      "go"             # needed to build Pebbles v2
      "herdr"          # primary multiplexer (agent-aware); tmux kept as fallback
      "jq"             # used constantly by our own tooling
      "lazygit"        # git TUI outside nvim (complements neogit, <leader>g)
      "neovim"
      "tmux"
      "yazi"           # terminal file manager w/ previews (complements oil.nvim, <leader>e)
      "zoxide"         # wired into home.nix shell config
    ];
    # Trimmed to just what this build actually needs. cleanup stays "none"
    # (see above), so dropping a cask here never removes it from a machine
    # that already has it — it just stops being auto-installed on new ones.
    casks = [
      "aerospace"
      # font-hack-nerd-font moved to nix (home.packages nerd-fonts.hack);
      # brew copy can be removed with: brew uninstall --cask font-hack-nerd-font
      "wezterm"
    ];
  };
}
