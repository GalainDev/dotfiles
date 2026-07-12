#!/usr/bin/env bash
# Apply config changes: edit flake.nix / configuration.nix / home.nix, then run this.
# (Files under home/ are live symlinks — they don't need a rebuild at all.)
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
exec sudo darwin-rebuild switch --flake ~/.dotfiles#mac
