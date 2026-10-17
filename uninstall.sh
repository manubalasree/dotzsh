#!/usr/bin/env bash
# Undo install.sh: restore your original ~/.zshrc and remove what we added.
#
#   ./uninstall.sh        asks before each destructive step
#   ./uninstall.sh -y     answers yes to the main steps (history and backups are
#                         still kept; add --purge to delete those as well)
#
# Touches only: ~/.zshrc, ~/.zsh_configs, ~/.cache/zsh, and (optionally) the
# history file and the ~/.zshrc.bak.* backups. Nothing else.
set -euo pipefail

YES=0; PURGE=0
for a in "$@"; do
  case "$a" in
    -y|--yes) YES=1 ;;
    --purge)  PURGE=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

DEST="${ZSH_CONFIGS:-$HOME/.zsh_configs}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
HIST="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
RC="$HOME/.zshrc"

ask() {  # ask "question" default(y|n)
  local q="$1" def="${2:-n}" reply
  if (( YES )); then [[ "$def" == y ]]; return; fi
  read -r -p "$q [$([[ $def == y ]] && echo Y/n || echo y/N)] " reply || reply=""
  reply="${reply:-$def}"
  [[ "$reply" =~ ^[Yy] ]]
}

# --- 1. ~/.zshrc: restore the OLDEST backup (the original) or remove ours ---
oldest=""; oldest_ts=""
shopt -s nullglob
for f in "$HOME"/.zshrc.bak.*; do
  ts="${f##*.}"
  [[ "$ts" =~ ^[0-9]+$ ]] || continue
  if [[ -z "$oldest_ts" || "$ts" -lt "$oldest_ts" ]]; then oldest="$f"; oldest_ts="$ts"; fi
done
shopt -u nullglob

if [[ -e "$RC" ]] && ! grep -q 'ZSH_CONFIGS' "$RC"; then
  # shellcheck disable=SC2088  # the tilde is meant literally, it's just a message
  echo "~/.zshrc does not look like this setup's (no ZSH_CONFIGS in it)."
  if ! ask "Replace it anyway?" n; then
    echo "Leaving ~/.zshrc alone."; oldest=""; SKIP_RC=1
  fi
fi

if [[ -z "${SKIP_RC:-}" ]]; then
  if [[ -n "$oldest" ]]; then
    echo "Original found: $oldest ($(date -r "$oldest_ts" 2>/dev/null || date -d "@$oldest_ts" 2>/dev/null || echo "timestamp $oldest_ts"))"
    if ask "Restore it as ~/.zshrc?" y; then
      rm -f "$RC"
      cp -P "$oldest" "$RC"       # -P: if the original was a symlink, restore the symlink itself
      echo "  restored"
    fi
  elif [[ -e "$RC" || -L "$RC" ]]; then
    echo "No backup found, so there was no ~/.zshrc before install."
    if ask "Remove ~/.zshrc?" y; then rm -f "$RC"; echo "  removed"; fi
  fi
fi

# --- 2. the config directory (only if it really is ours) ---
if [[ -d "$DEST" ]]; then
  if [[ -d "$DEST/core" && -d "$DEST/deferred" && "$DEST" != "/" && "$DEST" != "$HOME" ]]; then
    if ask "Delete $DEST (config + plugins)?" y; then rm -rf "$DEST"; echo "  deleted $DEST"; fi
  else
    echo "$DEST does not look like this setup's directory; leaving it alone."
  fi
fi

# --- 3. completion caches ---
if [[ -d "$CACHE" ]] && ask "Delete completion cache $CACHE?" y; then
  rm -rf "$CACHE"; echo "  deleted $CACHE"
fi

# --- 4. optional: history and backups (kept unless you opt in) ---
if [[ -f "$HIST" ]]; then
  if (( PURGE )) || { (( ! YES )) && ask "Delete the history file $HIST (commands typed with this setup)?" n; }; then
    rm -f "$HIST"; echo "  deleted history"
  else
    echo "Kept history: $HIST"
  fi
fi
if compgen -G "$HOME/.zshrc.bak.*" >/dev/null; then
  if (( PURGE )) || { (( ! YES )) && ask "Delete the ~/.zshrc.bak.* backups?" n; }; then
    rm -f "$HOME"/.zshrc.bak.*; echo "  deleted backups"
  else
    echo "Kept backups: ~/.zshrc.bak.*"
  fi
fi

echo "Done. Open a new terminal, or run: exec zsh"
