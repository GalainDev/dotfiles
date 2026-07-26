# Changelog

## 2026-07-27

### Neovim IDE foundation

- Added Treesitter support and parsers for TypeScript, TSX/React, JavaScript,
  Python, Go, Lua, Rust, and common web/config formats.
- Added automatic pairs, commenting, and surround editing.
- Added Mason-managed language servers for TypeScript, Python, Go, Lua, Rust,
  Ruff, and ESLint.
- Added LSP completion, snippets, hover documentation, definitions, references,
  implementations, rename, code actions, and diagnostic navigation.
- Added Conform-based format-on-save configuration for TypeScript/React,
  JavaScript, Python, Go, Lua, Rust, and common web/config formats.
- Added formatter tooling configuration for Prettierd, Ruff, and StyLua.
- Upgraded the local Homebrew Neovim installation to 0.12.4 so the current
  Treesitter setup is supported.

### Neovim keybindings

- Changed save from `Esc` to `Space w`.
- Aligned movement with the rest of the desktop setup: `j/k/l/;` move
  left/down/up/right in normal, visual, and operator-pending modes.
- Mapped `h` to repeat the last `f`/`t` character find.

### Follow-up

- Complete `:Lazy sync`, then confirm installed language servers/tools with
  `:Mason` and `:checkhealth`.
- Add debugging and test-runner support, then finalize the keybinding reference.
