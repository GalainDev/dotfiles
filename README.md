# dotfiles

My Mac, declared. nix-darwin + home-manager: one repo, one command, and a fresh
machine converges to this exact setup. Structure borrowed from
[kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles) (MIT-0), contents mine.

## Quick start (fresh machine)

```sh
git clone git@github.com:NamehYenad1/dotfiles.git
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
- **`.config/wezterm/wezterm.lua`** — rose-pine-moon, Hack Nerd Font 15pt, blur.
- **`.config/herdr/config.toml`** — herdr (primary multiplexer, agent-aware) with
  my tmux keybindings ported.
- **`.tmux.conf`** — kept as fallback during the herdr transition.

## Keybindings (herdr — same muscle memory as my tmux)

| Keys | Action |
|---|---|
| `C-b h` / `C-b n` | split side-by-side / top-bottom |
| `C-b j` `k` `l` `;` | focus pane left / down / up / right |
| `C-b c` / `C-b &` | new / close tab |
| `C-b w` / `C-b g` | workspace picker / goto |
| `C-b d` / `C-b r` | detach / reload config |
| `C-b [` | copy mode (vim keys inside) |

## Neovim survival card (learning)

| Keys | Action |
|---|---|
| `<space>f` / `<space>s` | find files / grep text |
| `<space>b` / `<space>e` | buffers / file browser (oil) |
| `<space>g` | neogit |
| `gd` | goto definition |
| `Esc` | **saves the file** (his quirk, kept) |
| `11k` / `11j` | jump 11 lines up/down (relative numbers) |
| `:q` | exit (you're welcome) |

## Homebrew policy

`onActivation.cleanup = "none"` — nix never uninstalls brew packages. Everything
already on this machine is declared in `configuration.nix`, so a fresh machine gets
the full set. Once the list has proven complete, flip to `"uninstall"` for fully
declarative package management. (Kun uses `"zap"` — do NOT copy that without reading
his README warning.)

## Learning exercises (in order)

1. Add `_HIHideMenuBar = true;` to `configuration.nix` → `./rebuild.sh` → menu bar hides.
2. Add `pkgs.ripgrep` to `home.packages` in `home.nix` → rebuild → `which rg` shows a /nix path.
3. Adopt `programs.zsh` + starship prompt (careful: back up `~/.zshrc` first — home-manager
   will want to own it).
4. Flip Homebrew cleanup to `"uninstall"` and remove something from the list.
