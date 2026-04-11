# dotfiles

My personal macOS configuration files.

## Structure

```
dotfiles/
├── aerospace/    # AeroSpace tiling window manager
├── tmux/         # tmux terminal multiplexer
```

## Setup

### AeroSpace
```bash
brew tap nikitabobko/tap
brew install nikitabobko/tap/aerospace
cp aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml
```

### tmux
```bash
brew install tmux
cp tmux/.tmux.conf ~/.tmux.conf
```
