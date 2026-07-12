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

echo "==> Step 3: sanity-check the flake user"
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix says user=\"$FLAKE_USER\" but you are \"$REAL_USER\" — edit flake.nix first."
  exit 1
fi
echo "    user \"$REAL_USER\" matches."

echo "==> Step 4: first darwin-rebuild switch"
# darwin-rebuild doesn't exist yet, so run it straight from the flake this once.
# sudo strips /nix/... from PATH, so resolve nix's absolute path first.
NIX_BIN="$(command -v nix)"
sudo "$NIX_BIN" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake ~/.dotfiles#mac

echo "==> Done. Use ./rebuild.sh for every future change."
