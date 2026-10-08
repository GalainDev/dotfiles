#!/usr/bin/env bash
# Fresh Mac → fully built nix-darwin config. Run ONCE; afterwards use ./rebuild.sh.
# Adapted from kunchenguid/dotfiles (MIT-0).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# must exist before the first switch.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: clone AI skills repo"
# home.nix symlinks .claude/skills and .codex/skills entries out of this repo
# (mkOutOfStoreSymlink doesn't clone anything — it just points at the path),
# so it must exist on disk before the first switch too. The repo is private, so
# clone through gh (run via nix — nothing else is installed yet) for the auth.
if [ ! -d ~/developer/AI ]; then
  mkdir -p ~/developer
  gh() { nix run nixpkgs#gh -- "$@"; }
  gh auth status >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web
  gh repo clone GalainDev/AI ~/developer/AI
else
  echo "    ~/developer/AI already exists, skipping"
fi

echo "==> Step 4: sanity-check the flake user"
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix says user=\"$FLAKE_USER\" but you are \"$REAL_USER\" — edit flake.nix first."
  exit 1
fi
echo "    user \"$REAL_USER\" matches."

echo "==> Step 5: first darwin-rebuild switch"
# darwin-rebuild doesn't exist yet, so run it straight from the flake this once.
# sudo strips /nix/... from PATH, so resolve nix's absolute path first.
NIX_BIN="$(command -v nix)"
sudo "$NIX_BIN" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake ~/.dotfiles#mac

echo "==> Done. Use ./rebuild.sh for every future change."
