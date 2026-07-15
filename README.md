# dotfiles

My Mac, declared. nix-darwin + home-manager: one repo, one command, and a fresh
machine converges to this exact setup. Structure borrowed from
[kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles) (MIT-0), contents mine.

## Quick start (fresh machine)

```sh
git clone git@github.com:GalainDev/dotfiles.git
cd dotfiles
./bootstrap.sh   # installs Determinate Nix, symlinks ~/.dotfiles, first switch
```

## Daily loop

- **Change a config file under `home/`** (nvim, wezterm, herdr, tmux): it's live
  immediately — these are symlinked in place, no rebuild.
- **Change a declaration** (`configuration.nix`, `home.nix`, `flake.nix` — packages,
  macOS defaults, new symlinks): apply with `./rebuild.sh`.

## Repo tour

| File | Layer | What it owns |
|---|---|---|
| `flake.nix` | entry point | pins inputs (nixpkgs, nix-darwin, home-manager, nix-homebrew); declares the `mac` machine; `user = "heman"` |
| `flake.lock` | pins | exact revisions of every input — reproducibility |
| `configuration.nix` | system | macOS defaults (dark mode, fast key repeat, dock autohide, Finder); the full Homebrew inventory (brews + casks) |
| `home.nix` | user | dotfile symlinks via `mkOutOfStoreSymlink`; env vars; nix packages |
| `home/` | configs | the real files, symlinked into `~` |
| `bootstrap.sh` | once | fresh-machine setup |
| `rebuild.sh` | always | `sudo darwin-rebuild switch --flake ~/.dotfiles#mac` |

### `home/` contents

- **`AGENTS.md`** — one global agent instruction file, fanned out by home.nix to
  `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`.
- **`.claude/settings.json`** — Claude Code hardening: auto permission mode +
  deny rules for secrets. Versioned, portable.
- **`.config/nvim/`** — Neovim, managed by **lazy.nvim**:
  - `lua/plugin.lua` bootstraps lazy.nvim itself (auto-clones on first launch)
  - `lua/plugins/*.lua` — one file per plugin area (colorscheme, git, navigation, ui);
    lazy.nvim loads every file in that directory as a plugin spec
  - `lazy-lock.json` — pins every plugin to an exact commit (committed; the plugin
    *code* lives in `~/.local/share/nvim/lazy/`, outside the repo, regenerated anywhere)
  - `lua/vim_config.lua` — options (space leader, relative numbers, no mouse)
  - `lua/keys.lua` — custom maps (Esc = save, Ctrl+A = select all)
- **`.config/wezterm/wezterm.lua`** — Tokyo Night, Hack Nerd Font 15pt, blur, native
  Cmd-based splits independent of herdr/tmux.
- **`.config/herdr/config.toml`** — herdr (primary multiplexer, agent-aware) with
  my tmux keybindings ported.
- **`.config/aerospace/`** — AeroSpace tiling WM config (alt-based, jkl; navigation —
  the same home-row scheme the herdr/tmux bindings mirror).
- **`.tmux.conf`** — kept as fallback during the herdr transition.

## Keybindings

Five layers, outside-in. `j`/`k`/`l`/`;` = left/down/up/right is the consistent home
row across AeroSpace, WezTerm, herdr, and tmux — deliberate, so the muscle memory
transfers between layers.

### AeroSpace (window manager — `Alt`, system-wide)

| Keys | Action |
|---|---|
| `Alt+j/k/l/;` or arrows | Focus window left/down/up/right |
| `Alt+Shift+j/k/l/;` or arrows | Move window left/down/up/right |
| `Alt+,` / `Alt+.` | Focus previous/next monitor |
| `Alt+Shift+,` / `Alt+Shift+.` | Move window to that monitor and follow |
| `Alt+Ctrl+,` / `Alt+Ctrl+.` | Move whole workspace to that monitor |
| `Alt+O` / `Alt+P` | Resize smaller / larger |
| `Alt+/` | Toggle tiles layout (horizontal↔vertical) |
| `Alt+\` | Toggle accordion layout |
| `Alt+F` | Fullscreen (AeroSpace-managed) |
| `Alt+Shift+F` | Float ↔ tile toggle |
| `Alt+Shift+B` | Balance window sizes |
| `Alt+1`–`9` | Switch to workspace 1–9 |
| `Alt+Shift+1`–`9` | Move window to workspace N and follow |
| `Alt+Tab` | Jump to previous workspace |
| `Alt+Shift+R` | Reload AeroSpace config |

### WezTerm (terminal — `Cmd`; works even with no multiplexer running)

| Keys | Action |
|---|---|
| `Cmd+H` | Split side-by-side |
| `Cmd+N` | Split top/bottom |
| `Cmd+J/K/L/;` | Focus pane left/down/up/right |
| `Cmd+W` | Close current pane |

### herdr (primary multiplexer — prefix `Ctrl+B`; run `herdr` to start)

| Keys | Action |
|---|---|
| `C-b h` / `C-b n` | Split side-by-side / top-bottom |
| `C-b j` `k` `l` `;` | Focus pane left / down / up / right |
| `C-b c` / `C-b &` | New tab / close tab |
| `C-b w` / `C-b g` | Workspace picker / goto |
| `C-b d` / `C-b r` | Detach / reload config |
| `C-b y` | Copy mode (then `v`/space select, `y`/Enter copy, `q`/Esc cancel) |

### tmux (fallback — same prefix `Ctrl+B`, only if launched directly instead of herdr)

Same `h`/`n` splits and `j/k/l/;` focus as herdr, plus `C-b r` reloads. Mouse
drag-to-copy also works. Resurrect/continuum auto-save the session every 15 min.

### Neovim (leader = `Space`, mouse disabled on purpose)

| Keys | Action |
|---|---|
| `Esc` | **Saves the file** (not just exits insert mode — his quirk, kept) |
| `Ctrl+A` | Select all |
| `<space>f` / `<space>s` | Find files / grep text |
| `<space>b` / `<space>e` | Buffers / file browser (oil) |
| `<space>g` | Git (neogit) |
| `gd` | Goto definition |
| `<space>` (then wait) | which-key popup — shows every live binding |
| `11k` / `11j` | Jump 11 lines up/down (relative numbers) |
| `:q` | Exit (you're welcome) |

## Homebrew policy

`onActivation.cleanup = "none"` — nix never uninstalls brew packages. Everything
already on this machine is declared in `configuration.nix`, so a fresh machine gets
the full set. Once the list has proven complete, flip to `"uninstall"` for fully
declarative package management. (Kun uses `"zap"` — do NOT copy that without reading
his README warning.)

## Learning exercises (in order)

1. Add `_HIHideMenuBar = true;` to `configuration.nix` → `./rebuild.sh` → menu bar hides.
2. Add `pkgs.ripgrep` to `home.packages` in `home.nix` → rebuild → `which rg` shows a /nix path.
3. Customize the starship prompt format in `home.nix` (shell layer is already managed:
   autosuggestions, syntax highlighting, fzf, zoxide, starship).
4. Flip Homebrew cleanup to `"uninstall"` and remove something from the list.
