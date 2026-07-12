# AeroSpace Config

My macOS tiling window manager setup using [AeroSpace](https://github.com/nikitabobko/AeroSpace) — a keyboard-driven i3-style tiler that replaces trackpad gestures for window and workspace navigation.

## Install

```bash
brew tap nikitabobko/tap
brew install nikitabobko/tap/aerospace
```

Copy the config:

```bash
mkdir -p ~/.config/aerospace
curl -o ~/.config/aerospace/aerospace.toml \
  https://raw.githubusercontent.com/NamehYenad1/aerospace-config/main/aerospace.toml
```

Then launch AeroSpace from `/Applications/AeroSpace.app` and grant it Accessibility permission in **System Settings → Privacy & Security → Accessibility**.

## Keybindings

All bindings use `Alt` (Option key on Mac).

### Focus

| Key | Action |
|-----|--------|
| `Alt + H/J/K/L` | Focus window left/down/up/right |
| `Alt + ←/↓/↑/→` | Same with arrow keys |

### Move Window

| Key | Action |
|-----|--------|
| `Alt + Shift + H/J/K/L` | Move window left/down/up/right |

### Resize

| Key | Action |
|-----|--------|
| `Alt + Ctrl + H/L` | Shrink/grow width |
| `Alt + Ctrl + J/K` | Grow/shrink height |

### Workspaces

| Key | Action |
|-----|--------|
| `Alt + 1-9` | Switch to workspace |
| `Alt + Shift + 1-9` | Move window to workspace (and follow) |
| `Alt + Tab` | Jump to previous workspace |

### Layout

| Key | Action |
|-----|--------|
| `Alt + /` | Toggle tiles (horizontal/vertical) |
| `Alt + \` | Toggle accordion layout |
| `Alt + F` | Toggle fullscreen |
| `Alt + Shift + F` | Toggle floating |
| `Alt + Shift + B` | Balance window sizes |

### Other

| Key | Action |
|-----|--------|
| `Alt + Shift + R` | Reload config |

## Gaps

8px inner and outer gaps on all sides.
