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

# Optional agent distro: firstmate is a git clone, not a brew/nix package, so
# nix cannot declare it. Ask once when missing (interactive terminals only);
# the repo is self-contained and updates itself via git pull inside it.
# After install, write config/backend = herdr: this config has no tmux, and
# herdr (already installed) is firstmate's native experimental backend here.
FM_DIR="${FIRSTMATE_DIR:-$HOME/code/firstmate}"
if [ ! -d "$FM_DIR/.git" ] && [ -t 1 ]; then
  read -r -p "    firstmate is not installed at $FM_DIR. Install it? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    mkdir -p "$(dirname "$FM_DIR")"
    git clone https://github.com/kunchenguid/firstmate "$FM_DIR"
    if command -v tmux >/dev/null 2>&1; then
      echo "    Installed. Launch with: cd $FM_DIR && pi"
    else
      mkdir -p "$FM_DIR/config"
      printf 'herdr\n' > "$FM_DIR/config/backend"
      echo "    Installed with config/backend = herdr (no tmux on this machine)."
      echo "    Launch with: cd $FM_DIR && pi"
    fi
  fi
fi

exec sudo darwin-rebuild switch --flake ~/.dotfiles#mac
