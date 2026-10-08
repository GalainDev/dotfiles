# Dotfiles Cheatsheet

## AeroSpace

| Keys | Action |
|---|---|
| Option+J/K/L/; or arrows | Focus left/down/up/right window |
| Option+Shift+J/K/L/; or arrows | Move window |
| Option+, / Option+. | Focus previous/next monitor |
| Option+Shift+, / Option+Shift+. | Move window to previous/next monitor and follow |
| Option+Ctrl+, / Option+Ctrl+. | Move workspace to previous/next monitor |
| Option+O / Option+P | Resize smaller/larger |
| Option+/ | Cycle tiled layouts |
| Option+\\ | Cycle accordion layouts |
| Option+F | AeroSpace fullscreen |
| Option+Shift+F | Toggle floating/tiled |
| Option+Shift+B | Balance window sizes |
| Option+1–9 | Switch to workspace 1–9 |
| Option+Shift+1–9 | Move window to workspace 1–9 and follow |
| Option+Tab | Previous workspace |
| Option+Shift+R | Reload config |

## WezTerm

| Keys | Action |
|---|---|
| Cmd+H | Split side-by-side |
| Cmd+N | Split top/bottom |
| Cmd+J/K/L/; | Focus left/down/up/right pane |
| Cmd+Option+J/K/L/; | Resize pane left/down/up/right |
| Cmd+Option+R | Rotate panes |
| Cmd+W | Close pane |
| Cmd+Shift+W | Close tab |

## herdr

Prefix: `Ctrl+b` (press and release it before the second key).

| Keys | Action |
|---|---|
| Prefix+C | Create tab |
| Prefix+& | Close tab |
| Prefix+J/K/L/; | Focus left/down/up/right pane |
| Prefix+H | Split side-by-side |
| Prefix+N | Split top/bottom |
| Prefix+W | Open workspace/space picker and switch spaces |
| Prefix+G | Go to a target |
| Prefix+A | Next agent |
| Prefix+Shift+A | Previous agent |
| Prefix+Y | Copy mode (`v`/Space select; `y`/Enter copy; `q`/Esc cancel) |
| Prefix+D | Detach |
| Prefix+Shift+R | Reload config |

## tmux

Prefix: `Ctrl+b`.

| Keys | Action |
|---|---|
| Prefix+H | Split side-by-side |
| Prefix+N | Split top/bottom |
| Prefix+J/K/L/; | Focus left/down/up/right pane |
| Prefix+R | Reload config |

## Neovim

| Keys | Action |
|---|---|
| Esc | Save |
| Ctrl+A | Select all |
| Leader+G | Open Neogit |
| Leader+E | File browser |
| Leader+F | Find files |
| Leader+S | Search text |
| Leader+B | Switch buffers |
| gd | Go to definition |

## CLI Tools

| Tool | Most-used commands / bindings |
|---|---|
| zoxide | `z <dir>` jump; `zi` interactive jump |
| fzf | Ctrl+R fuzzy history; Ctrl+T fuzzy file selection |
| bat | `bat <file>` syntax-highlighted file viewer |
| fd | `fd <pattern>` fast file search; `fd -t f` files only |
| lazygit | `lazygit` open Git UI |
| yazi | `yazi` open file manager |
| gh | `gh pr status`; `gh pr create`; `gh repo view` |
| jq | `jq '.' file.json`; `jq '.field' file.json` |
| glow | `glow README.md` render Markdown in the terminal |
