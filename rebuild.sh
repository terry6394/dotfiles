#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# Pre-flight: flake.nix's username must match this machine's account, or the
# switch would configure the wrong user. A mismatch usually means bootstrap.sh's
# personalization was lost (e.g. after `git checkout -- flake.nix` or a reset).
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "rebuild: could not find the \"user = \" line in flake.nix - fix it first." >&2
  exit 1
fi
if [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "rebuild: flake.nix is configured for user \"$FLAKE_USER\" but you are \"$REAL_USER\"." >&2
  echo "  Run ./bootstrap.sh to re-personalize, or edit flake.nix's user line yourself." >&2
  exit 1
fi

# Pre-flight: the machine label must exist, or the per-machine software tier
# silently collapses to common-only. bootstrap.sh sets it interactively.
FLAKE_MACHINE="$(sed -nE 's/^[[:space:]]*machine = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_MACHINE" ]; then
  echo "rebuild: no machine label in flake.nix - run ./bootstrap.sh to set it." >&2
  exit 1
fi

exec sudo darwin-rebuild switch --flake ~/.dotfiles#mac
